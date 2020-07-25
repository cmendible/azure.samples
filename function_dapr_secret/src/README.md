
## Run Function App with Dapr

```shell
dapr run --app-id functionapp --app-port 3001 --port 3501 --components-path .\components\ -- func host start
```

## Invoke the function: 

```shell
dapr invoke --app-id functionapp --method GetSecret
```

```shell
curl -i -X POST http://127.0.0.1:3501/v1.0/invoke/functionapp/method/GetSecret
```