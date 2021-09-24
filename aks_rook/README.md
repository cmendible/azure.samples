## Deploy cluster with Rook Ceph using Terraform

Get the cluster credentials:

``` shell
az aks get-credentials --resource-group <resource group name> --name <aks name>
```

From the terraform folder run:

``` shell
terraform init
terraform apply -auto-approve
```

## Deploy Test Application

Deploy the test application using the following command:

``` shell
kubectl apply -f ceph-filesystem-pvc.yaml
kubectl apply -f busybox-deployment.yaml
```

Check the pvc status:

``` shell	
kubectl get pvc
```

The output should look like this (Note the status is "Bound"):

``` shell	
NAME                  STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS      AGE
ceph-filesystem-pvc   Bound    pvc-344e2517-b421-4a81-98e2-5bc6a991d93d   1Gi        RWX            ceph-filesystem   21h   
```

Check `important.file` exists:

``` shell	
kubectl exec $(kubectl get po -l app=busy -o jsonpath='{.items[0].metadata.name}') -it -- cat /ceph-file-store/important.file
```

you should get the contents of `important.file`:

``` shell
yada yada yada
```

## Performance Tests

Using [kubestr](https://github.com/kastenhq/kubestr)

``` shell	
.\kubestr.exe fio -z 20Gi -s ceph-filesystem
```

``` shell	
PVC created kubestr-fio-pvc-6hvqr
Pod created kubestr-fio-pod-nmbmr
Running FIO test (default-fio) on StorageClass (ceph-filesystem) with a PVC of Size (20Gi)
Elapsed time- 2m35.1500188s
FIO test results:

FIO version - fio-3.20
Global options - ioengine=libaio verify=0 direct=1 gtod_reduce=1

JobName: read_iops
  blocksize=4K filesize=2G iodepth=64 rw=randread
read:
  IOPS=1583.366333 BW(KiB/s)=6350
  iops: min=1006 max=2280 avg=1599.766724
  bw(KiB/s): min=4024 max=9120 avg=6399.233398

JobName: write_iops
  blocksize=4K filesize=2G iodepth=64 rw=randwrite
write:
  IOPS=223.526337 BW(KiB/s)=910
  iops: min=124 max=305 avg=224.199997
  bw(KiB/s): min=496 max=1221 avg=897.133362

JobName: read_bw
  blocksize=128K filesize=2G iodepth=64 rw=randread
read:
  IOPS=1565.778198 BW(KiB/s)=200950
  iops: min=968 max=2214 avg=1583.266724
  bw(KiB/s): min=123904 max=283392 avg=202674.265625

JobName: write_bw
  blocksize=128k filesize=2G iodepth=64 rw=randwrite
write:
  IOPS=225.524933 BW(KiB/s)=29396
  iops: min=124 max=308 avg=227.033340
  bw(KiB/s): min=15872 max=39424 avg=29077.132812

Disk stats (read/write):
  -  OK
```

``` shell	
.\kubestr.exe fio -z 20Gi -s azurefile-csi-premium
```

``` shell
PVC created kubestr-fio-pvc-mvf9v
Pod created kubestr-fio-pod-qntnw
Running FIO test (default-fio) on StorageClass (azurefile-csi-premium) with a PVC of Size (20Gi)
Elapsed time- 59.3141476s
FIO test results:

FIO version - fio-3.20
Global options - ioengine=libaio verify=0 direct=1 gtod_reduce=1

JobName: read_iops
  blocksize=4K filesize=2G iodepth=64 rw=randread
read:
  IOPS=557.804260 BW(KiB/s)=2247
  iops: min=260 max=1294 avg=644.807678
  bw(KiB/s): min=1040 max=5176 avg=2579.384521

JobName: write_iops
  blocksize=4K filesize=2G iodepth=64 rw=randwrite
write:
  IOPS=255.239807 BW(KiB/s)=1037
  iops: min=6 max=428 avg=292.037048
  bw(KiB/s): min=24 max=1712 avg=1168.333374

JobName: read_bw
  blocksize=128K filesize=2G iodepth=64 rw=randread
read:
  IOPS=537.072571 BW(KiB/s)=69278
  iops: min=260 max=1358 avg=622.115356
  bw(KiB/s): min=33280 max=173824 avg=79648.304688

JobName: write_bw
  blocksize=128k filesize=2G iodepth=64 rw=randwrite
write:
  IOPS=295.383789 BW(KiB/s)=38343
  iops: min=144 max=872 avg=340.846161
  bw(KiB/s): min=18432 max=111616 avg=43637.308594

Disk stats (read/write):
  -  OK
````

## Simulate VM crash

``` shell
kubectl get po -l app=rook-ceph-osd -n rook-ceph -o wide
```

Simulate a VM crash:

``` shell
$resourceGroup=$(az aks show --resource-group aks-rook --name aks-rook --query "nodeResourceGroup" --output tsv)
$cephScaleSet=$(az vmss list --resource-group $resourceGroup --query "[].{name:name}[? contains(name,'npceph')] | [0].name" --output tsv)
az vmss deallocate --resource-group $resourceGroup --name $cephScaleSet --instance-ids 0
```

Restart the server:

``` shell
az vmss start --resource-group $resourceGroup --name $cephScaleSet --instance-ids 0        
```

## Installing Rook Ceph existing AKS using helm

``` shell
helm repo add rook-release https://charts.rook.io/release
```

``` shell
helm install --create-namespace --namespace rook-ceph rook-ceph rook-release/rook-ceph --version 1.7.3 -f ./deploy/rook-ceph-operator-values 
``` 

``` shell
helm install --create-namespace --namespace rook-ceph rook-ceph-cluster --version 1.7.3 rook-release/rook-ceph-cluster -f ./deploy/rook-ceph-cluster-values.yaml
``` 
