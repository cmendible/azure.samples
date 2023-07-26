"Azure AD Workload Identity is not allowed to enable since feature flag \"Microsoft.ContainerService/EnableWorkloadIdentityPreview\" is not registered. Please see https://aka.ms/aks/wi for how to register the feature flag."

az feature register --namespace "Microsoft.ContainerService" --name "EnableWorkloadIdentityPreview"

az feature show --namespace "Microsoft.ContainerService" --name "EnableWorkloadIdentityPreview"

az provider register --namespace Microsoft.ContainerService

---

az login wihtout the sidecar:

```bash 
az login --federated-token "$(cat  $AZURE_FEDERATED_TOKEN_FILE)" --service-principal -u $AZURE_CLIENT_ID -t $AZURE_TENANT_ID
```