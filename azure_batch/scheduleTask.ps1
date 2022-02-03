${env:batch_url}=$(terraform output -raw batch_url)
${env:batch_accountName}=$(terraform output -raw batch_accountName)
${env:batch_key}=$(terraform output -raw batch_key)
${env:storage_name}=$(terraform output -raw storage_name)
${env:storage_key}=$(terraform output -raw storage_key)

dotnet run --project .\batch\batch.csproj