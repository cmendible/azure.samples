${env:batch_url}=$(terraform output -raw batch_url)
${env:batch_accountName}=$(terraform output -raw batch_accountName)
${env:storage_name}=$(terraform output -raw storage_name)
${env:storage_key}=$(terraform output -raw storage_key)
${env:client_id}=$(terraform output -raw client_id)
${env:client_secret}=$(terraform output -raw client_secret)
${env:tenant_id}=$(terraform output -raw tenant_id)

dotnet run --project .\batch\batch.csproj