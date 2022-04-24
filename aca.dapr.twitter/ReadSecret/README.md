docker build -t cmendibl3/dapr-read-secret .
docker push cmendibl3/dapr-read-secret

dapr run -a read-tweets -p 5051 --components-path .\components\ -- dotnet run
