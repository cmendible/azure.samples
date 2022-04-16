docker build -t cmendibl3/dapr-read-twitter .
docker push cmendibl3/dapr-read-twitter

dapr run -a read-tweets -p 5059 --components-path .\components\ -- dotnet run

ContainerAppConsoleLogs_CL 
| where ContainerAppName_s == 'read-twitter' 
| project State_Message_s, TimeGenerated 
| order by TimeGenerated desc 