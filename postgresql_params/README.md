``` bash
az group create --name postgresql --location westeurope

az deployment group create \
  --name ExampleDeployment \
  --resource-group postgresql \
  --template-file ./deploy.json  \
  --parameters @'./params.json'
``` 