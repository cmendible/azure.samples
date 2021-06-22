```shell
docker build -t cmendibl3/signalr-server .
docker push cmendibl3/signalr-server
```

```
// List container logs per namespace 
// View container logs from all the namespaces in the cluster. 
ContainerLog
|join(KubePodInventory| where TimeGenerated > ago(2h))//KubePodInventory Contains namespace information
on ContainerID
|where TimeGenerated > ago(2h)
| project TimeGenerated ,Namespace , LogEntrySource , LogEntry
| where LogEntry contains "exception" and not(LogEntry contains "exception pod")
```
