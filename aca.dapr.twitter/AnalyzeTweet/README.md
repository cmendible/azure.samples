docker build -t cmendibl3/dapr-analyze-tweet .
docker push cmendibl3/dapr-analyze-tweet

dapr run -a analyze-tweet -p 5059 --components-path .\components\ -- dotnet run

ContainerAppConsoleLogs_CL 
| where ContainerAppName_s == 'analyze-tweet' 
| project State_Message_s, TimeGenerated 
| order by TimeGenerated desc 