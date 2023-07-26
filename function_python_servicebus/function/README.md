[Service Bus Binding settings](https://learn.microsoft.com/en-us/azure/azure-functions/functions-bindings-service-bus?tabs=in-process,extensionv5,extensionv3&pivots=programming-language-python#hostjson-settings)

The maxConcurrentCalls works at the host level and it's used in conjunction with the MaxConcurrentSessions property to control the maximum number of messages each function processes concurrently on each instance.

Inside `host.json`:

``` json
"extensions": {
    "serviceBus": {
      "maxConcurrentCalls": 1
    }
  }
```

> If your app has multiple Functions the `maxConcurrentCalls` property applies to all/across Functions within the host, not per Function.