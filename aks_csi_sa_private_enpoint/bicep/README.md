az group create -n my-rg -l westeurope

az deployment group create -f ./main.bicep -g my-rg

az aks get-credentials -n akscsimsft -g my-rg --overwrite-existing

curl -skSL https://raw.githubusercontent.com/kubernetes-sigs/azurefile-csi-driver/v1.1.0/deploy/install-driver.sh | bash -s v1.1.0 --

sed 's/<resourceGroup>/my-rg/;s/<storageAccountName>/akscsisa/' ../storageclass-azurefile-csi.yaml | kubectl apply -f -

k get pvc

az group delete -n my-rg