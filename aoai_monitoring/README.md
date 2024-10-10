## Deploy infrastructure

```bash
cd infra
terraform apply
```

## Run the sample application

```bash
export OPENAI_ENDPOINT=$(terraform output -raw endpoint)
dotnet run --project ../src/aoai_monitoring.csproj
```

## Check Application Insights requests logs and compare with Azure Monitor


