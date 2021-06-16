```shell
docker build -t cmendibl3/signalr-server .
docker push cmendibl3/signalr-server
```

```
// List container logs per namespace 
// View container logs from all the namespaces in the cluster. 
ContainerLog
|join(KubePodInventory| where TimeGenerated > startofday(ago(1h)))//KubePodInventory Contains namespace information
on ContainerID
|where TimeGenerated > startofday(ago(1h))
| project TimeGenerated ,Namespace , LogEntrySource , LogEntry
| where LogEntry contains "1006"
```
