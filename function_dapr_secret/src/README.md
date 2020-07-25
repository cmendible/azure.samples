
## Run Function App with Dapr

```shell
dapr run --app-id functionapp --app-port 3001 --port 3501 --components-path .\components\ -- func host start
```

## Invoke the function: 

```shell
curl -k -i http://localhost:7071/api/secret
```