#!/bin/bash

# Parameters
registryName=$1
repository=$2
tag=$3
scanExtractionRetryCount=${4:-3}
mediumFindingsCountFailThreshold=${5:-5}
lowFindingsCountFailThreshold=${6:-15}

# Get image digest
imageDigest=$(az acr repository show -n "$registryName" --image "$repository:$tag" -o tsv --query digest)
if [ -z "$imageDigest" ]; then
    echo "Image '$repository:$tag' was not found! (Registry: $registryName)" >&2
    exit 1
fi

echo "Image Digest: $imageDigest"

# All images scan summary ARG query
query="securityresources
 | where type == 'microsoft.security/assessments/subassessments'
 | where id matches regex  '(.+?)/providers/Microsoft.ContainerRegistry/registries/(.+)/providers/Microsoft.Security/assessments/c0b7cfc6-3172-465a-b378-53c7ff2cc0d5/'
 | extend registryResourceId = tostring(split(id, '/providers/Microsoft.Security/assessments/')[0])
 | extend registryResourceName = tostring(split(registryResourceId, '/providers/Microsoft.ContainerRegistry/registries/')[1])
 | extend imageDigest = tostring(properties.additionalData.artifactDetails.digest)
 | extend repository = tostring(properties.additionalData.artifactDetails.repositoryName)
 | extend tags = tostring(properties.additionalData.artifactDetails.tags)
 | extend scanFindingSeverity = tostring(properties.status.severity), scanStatus = tostring(properties.status.code)
 | summarize findingsCountOverAll = count(), scanFindingSeverityCount = count() by scanFindingSeverity, scanStatus, registryResourceId, registryResourceName, repository, imageDigest, tags
 | summarize findingsCountOverAll = sum(findingsCountOverAll), severitySummary = make_bag(pack(scanFindingSeverity, scanFindingSeverityCount)) by registryResourceId, registryResourceName, repository, imageDigest, tags, scanStatus
 | summarize findingsCountOverAll = sum(findingsCountOverAll) , scanReport = make_bag_if(pack('scanStatus', scanStatus, 'scanSummary', severitySummary), scanStatus != 'NotApplicable')by registryResourceId, registryResourceName, repository, imageDigest, tags
 | extend IsScanned = iif(findingsCountOverAll > 0, true, false)"

# Add filter to get scan summary for specific provided image
filter="| where imageDigest =~ '$imageDigest' and repository =~ '$repository' and registryResourceName =~ '$registryName'"
query="$query $filter"

echo "Query: $query"

# Remove query's new line to use ARG CLI
query=$(echo "$query" | tr -d '\n' | tr -d '\r')

# Get result with retry policy
i=0
result=$(az graph query -q "$query" -o json)
while [ $(echo "$result" | jq '.count') -eq 0 ] && [ $i -lt $scanExtractionRetryCount ]; do
    echo "No results for image $repository:$tag yet ..."
    sleep 20
    i=$((i + 1))
    result=$(az graph query -q "$query" -o json)
done

if [ $(echo "$result" | jq '.count') -eq 0 ]; then
    echo "No results were found for digest: $imageDigest after $scanExtractionRetryCount retries!" >&2
    exit 1
fi

if [ $(echo "$result" | jq '.count') -gt 1 ]; then
    echo "Too many rows returned, unknown issue $imageDigest, investigate returned result on top ARG" >&2
    exit 1
fi

# Extract scan summary from result
scanReportRow=$(echo "$result" | jq '.data[0]')
echo "Scan report row: $scanReportRow"

if [ $(echo "$scanReportRow" | jq '.IsScanned') -ne 1 ]; then
    echo "Image not scanned, image: $imageDigest" >&2
    exit 1
fi

scanReport=$(echo "$scanReportRow" | jq '.scanReport')
echo "Scan report $scanReport"

scanStatus=$(echo "$scanReport" | jq -r '.scanStatus')
if [ "$scanStatus" = "Unhealthy" ]; then
    scanSummary=$(echo "$scanReport" | jq '.scanSummary')
    high=$(echo "$scanSummary" | jq '.High')
    medium=$(echo "$scanSummary" | jq '.Medium')
    low=$(echo "$scanSummary" | jq '.Low')
    if [ "$high" -gt 0 ] || [ "$medium" -gt "$mediumFindingsCountFailThreshold" ] || [ "$low" -gt "$lowFindingsCountFailThreshold" ]; then
        echo "Unhealthy scan result, major vulnerabilities found in image summary" >&2
        exit 1
    else
        echo "Healthy scan result, as vulnerabilities found in image did not surpass thresholds"
        exit 0
    fi
elif [ "$scanStatus" = "Healthy" ]; then
    echo "Healthy Scan found for image!"
    exit 0
else
    echo "All non Applicable results Scan -> default as all findings non applicable"
    exit 0
fi
