# Azure Functions with Python and Azure Service Bus Topics and Queues

## Service Bus Bindings for Azure Functions

Check the [Service Bus Binding settings](https://learn.microsoft.com/en-us/azure/azure-functions/functions-bindings-service-bus?tabs=in-process,extensionv5,extensionv3&pivots=programming-language-python#hostjson-settings) to understand how each setting works.

## maxConcurrentCalls

The **maxConcurrentCalls** works at the host level and it's used in conjunction with the **maxConcurrentSessions** property to control the maximum number of messages each function processes concurrently on each instance.

These seetings are conigured in the `host.json` file:

``` json
"extensions": {
    "serviceBus": {
      "maxConcurrentCalls": 1
    }
  }
```

**maxConcurrentCalls** can be overridden if **dynamicConcurrencyEnabled** is set to true in the host.json file. This allows the host to dynamically scale the number of concurrent calls based on the number of messages in the queue or subscription. The default value is false. Check for more information [here](https://learn.microsoft.com/en-us/azure/azure-functions/functions-concurrency#dynamic-concurrency-configuration)

## Working Configuration

* Since no awaitable methods or call is used, all methods are synchronous. (no async/await)
* The **maxConcurrentCalls** is set to 1 in the `host.json` file.
* The **dynamicConcurrencyEnabled** is not set in the `host.json` file. So it's false by default.
* Inside the Azure Function configuration:
    * **FUNCTIONS_WORKER_PROCESS_COUNT** is set to 1
    * **PYTHON_THREADPOOL_THREAD_COUNT** is set to None
* Messages are sent to the Service Bus Queue using output bindings.

## More Information

* [Azure Functions Python developer guide](https://learn.microsoft.com/en-us/azure/azure-functions/functions-reference-python?tabs=asgi,application-level&pivots=python-mode-configuration)
* [Best Practices for performance improvements using Service Bus Messaging](https://learn.microsoft.com/en-us/azure/service-bus-messaging/service-bus-performance-improvements?tabs=net-standard-sdk-2)
* [Improve throughput performance of Python apps in Azure Functions](https://learn.microsoft.com/en-us/azure/azure-functions/python-scale-performance-reference#use-multiple-language-worker-processes)