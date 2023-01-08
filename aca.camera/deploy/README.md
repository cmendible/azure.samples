# Create the resource group

``` shell
az group create -n aca-camera -l eastus
```

# Create the bicep deployment

``` shell
az deployment group create -g aca-camera --template-file main.bicep
```

# Logs Analytics Query

``` shell
ContainerAppConsoleLogs_CL 
| where ContainerAppName_s == 'camera-control' 
| project Log_State_Message_s, TimeGenerated 
| order by TimeGenerated desc 
```

# Log stream

``` shell
az containerapp logs show -n camera-control -g aca-camera
```

# Connect to Console

``` shell
az containerapp exec -n camera-control -g aca-camera --command bash
```

# Cleanup

``` shell
az group delete -n aca-camera
```

## References:

* [Azure Container Apps Virtual Network Integration](https://techcommunity.microsoft.com/t5/apps-on-azure-blog/azure-container-apps-virtual-network-integration/ba-p/3096932)
* [Quickstart: Deploy your first container app](https://docs.microsoft.com/en-us/azure/container-apps/get-started?ocid=AID3042118&tabs=bash)
* [Azure Container Apps GitHub](https://github.com/microsoft/azure-container-apps)