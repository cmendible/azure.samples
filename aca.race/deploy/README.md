# Create the resource group

``` shell
az group create -n private-container-apps-sample -l eastus
```

# Create the bicep deployment

``` shell
az deployment group create -g private-container-apps-sample --template-file main.bicep
```

# Logs Analytics Query

``` shell
ContainerAppConsoleLogs_CL 
| where ContainerAppName_s == 'read-twitter' 
| project State_Message_s, TimeGenerated 
| order by TimeGenerated desc 
``` 

# Cleanup

``` shell
az group delete -n private-container-apps-sample
```

## References:

* [Azure Container Apps Virtual Network Integration](https://techcommunity.microsoft.com/t5/apps-on-azure-blog/azure-container-apps-virtual-network-integration/ba-p/3096932)
* [Quickstart: Deploy your first container app](https://docs.microsoft.com/en-us/azure/container-apps/get-started?ocid=AID3042118&tabs=bash)
* [Azure Container Apps GitHub](https://github.com/microsoft/azure-container-apps)