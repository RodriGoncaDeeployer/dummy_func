# What is it?

This is a dummy Azure Function project that demonstrates a critical error occurring with the Azure Functions Python 3.13 container image `mcr.microsoft.com/azure-functions/python:4-python3.13`.

## Problem Description

The Azure Functions runtime fails to start when using certain Python packages, specifically `google-cloud-aiplatform` which depends on `grpcio`. The error appears to be a dependency conflict between pre-installed packages in the container image and packages installed in the virtual environment.

## Root Cause

The issue seems to be related to the new dependency isolation feature introduced in Azure Functions Python 3.13:

> **Dependency isolation now enabled by default** ([Learn more](https://learn.microsoft.com/en-us/azure/azure-functions/python-313-changes))
> 
> *Your apps can now benefit from full dependency isolation, which means that when your app includes a dependency that's also used by the Python worker, such as azure-functions or grpcio, your app can use its own version even though the Python runtime uses a different version internally. This isolation prevents version conflicts and improves compatibility with custom packages.*

## Environment Comparison

| Environment | Python Version | Container Image | Status |
|-------------|---------------|-----------------|---------|
| Local (func start) | 3.13 | N/A | ✅ Works |
| Docker | 3.12 | `mcr.microsoft.com/azure-functions/python:4-python3.12` | ✅ Works |
| Cloud Deployment | 3.12 | `mcr.microsoft.com/azure-functions/python:4-python3.12` | ✅ Works |
| Docker | 3.13 | `mcr.microsoft.com/azure-functions/python:4-python3.13` | ❌ Fails |
| Cloud Deployment | 3.13 | `mcr.microsoft.com/azure-functions/python:4-python3.13` | ❌ Fails |

The error only occurs when running the Python 3.13 container image with Docker, suggesting the issue is specific to the containerized environment's dependency isolation implementation.

# How to reproduce the error using `mcr.microsoft.com/azure-functions/python:4-python3.13` image.
1. Clone this repository.
2. Switch to `fail` branch: `git checkout fail`.
3. Build the Docker image: `docker compose build`.
4. Run the Docker container: `docker compose up --force-recreate`.
5. Wait approximately 2 minutes for the error to manifest.

The Azure Functions runtime will fail to start when the import `from google.api_core.exceptions import NotFound` is uncommented in `function_app.py`. This import triggers the dependency conflict that causes the Python worker to crash with exit code 139.

Try commenting and uncommenting the import line to see the difference in behavior.

## Error log snippet
``` log
...
dummy-func     | dbug: Microsoft.Azure.WebJobs.Script.Workers.Rpc.RpcFunctionInvocationDispatcher[0]
dummy-func     |       Handling WorkerErrorEvent for runtime:python, workerId:python. Failed with: Microsoft.Azure.WebJobs.Script.Workers.WorkerProcessExitException: python exited with code 139 (0x8B)
dummy-func     |        ---> System.Exception
dummy-func     |          --- End of inner exception stack trace ---
dummy-func     | dbug: Microsoft.Azure.WebJobs.Script.Workers.Rpc.RpcFunctionInvocationDispatcher[0]
dummy-func     |       Attempting to dispose webhost or jobhost channel for workerId: '98b7cf7b-502d-49c1-8739-195b21895722', runtime: 'python'
dummy-func     | dbug: Microsoft.Azure.WebJobs.Script.Workers.Rpc.RpcFunctionInvocationDispatcher[0]
dummy-func     |       No initialized worker channels for runtime 'python'. Delaying future invocations
dummy-func     | dbug: Microsoft.Azure.WebJobs.Script.Workers.Rpc.RpcFunctionInvocationDispatcher[0]
dummy-func     |       Restarting worker channel for runtime: 'python'
dummy-func     | fail: Microsoft.Azure.WebJobs.Script.Workers.Rpc.RpcFunctionInvocationDispatcher[0]
dummy-func     |       Exceeded language worker restart retry count for runtime:python. Shutting down and proactively recycling the Functions Host to recover
...
dummy-func     | warn: Host.Startup[0]
dummy-func     |       No job functions found. Try making your job classes and methods public. If you're using binding extensions (e.g. Azure Storage, ServiceBus, Timers, etc.) make sure you've called the registration method for the extension(s) in your startup code (e.g. builder.AddAzureStorage(), builder.AddServiceBus(), builder.AddTimers(), etc.).
```

# How to verify the issue doesn't occur in working environments

## Local Development (Python 3.13) - ✅ Works
1. Switch to the failing branch: `git checkout fail`
2. Install uv package manager: `pip install uv`
3. Create and sync virtual environment: `uv sync`
4. Activate the virtual environment:
    - **Windows**: `.venv/Scripts/Activate`
    - **macOS/Linux**: `source .venv/bin/activate`
5. Start the Azure Functions runtime: `func start`
6. Test the function: Visit `http://localhost:7071/api/endpoint`

## Docker with Python 3.12 - ✅ Works
1. Switch to the working branch: `git checkout success`
2. Build the Docker image: `docker compose build`
3. Start the container: `docker compose up --force-recreate`
4. Test the function: Visit `http://localhost:7071/api/endpoint`

These steps demonstrate that the issue is specifically isolated to the Azure Functions Python 3.13 container image (`mcr.microsoft.com/azure-functions/python:4-python3.13`) and not related to Python 3.13 itself or the function code.

### Dependency tree
``` log
dummy-func v1.0.0
├── azure-functions v1.24.0
│   └── werkzeug v3.1.3
│       └── markupsafe v3.0.3
└── google-cloud-aiplatform v1.121.0
    ├── docstring-parser v0.17.0
    ├── google-api-core[grpc] v2.26.0
    │   ├── google-auth v2.41.1
    │   │   ├── cachetools v6.2.1
    │   │   ├── pyasn1-modules v0.4.2
    │   │   │   └── pyasn1 v0.6.1
    │   │   └── rsa v4.9.1
    │   │       └── pyasn1 v0.6.1
    │   ├── googleapis-common-protos v1.71.0
    │   │   ├── protobuf v6.33.0
    │   │   └── grpcio v1.75.1 (extra: grpc)
    │   │       └── typing-extensions v4.15.0
    │   ├── proto-plus v1.26.1
    │   │   └── protobuf v6.33.0
    │   ├── protobuf v6.33.0
    │   ├── requests v2.32.5
    │   │   ├── certifi v2025.10.5
    │   │   ├── charset-normalizer v3.4.4
    │   │   ├── idna v3.11
    │   │   └── urllib3 v2.5.0
    │   ├── grpcio v1.75.1 (extra: grpc) (*)
    │   └── grpcio-status v1.75.1 (extra: grpc)
    │       ├── googleapis-common-protos v1.71.0 (*)
    │       ├── grpcio v1.75.1 (*)
    │       └── protobuf v6.33.0
    ├── google-auth v2.41.1 (*)
    ├── google-cloud-bigquery v3.38.0
    │   ├── google-api-core[grpc] v2.26.0 (*)
    │   ├── google-auth v2.41.1 (*)
    │   ├── google-cloud-core v2.4.3
    │   │   ├── google-api-core v2.26.0 (*)
    │   │   └── google-auth v2.41.1 (*)
    │   ├── google-resumable-media v2.7.2
    │   │   └── google-crc32c v1.7.1
    │   ├── packaging v25.0
    │   ├── python-dateutil v2.9.0.post0
    │   │   └── six v1.17.0
    │   └── requests v2.32.5 (*)
    ├── google-cloud-resource-manager v1.15.0
    │   ├── google-api-core[grpc] v2.26.0 (*)
    │   ├── google-auth v2.41.1 (*)
    │   ├── grpc-google-iam-v1 v0.14.3
    │   │   ├── googleapis-common-protos[grpc] v1.71.0 (*)
    │   │   ├── grpcio v1.75.1 (*)
    │   │   └── protobuf v6.33.0
    │   ├── grpcio v1.75.1 (*)
    │   ├── proto-plus v1.26.1 (*)
    │   └── protobuf v6.33.0
    ├── google-cloud-storage v2.19.0
    │   ├── google-api-core v2.26.0 (*)
    │   ├── google-auth v2.41.1 (*)
    │   ├── google-cloud-core v2.4.3 (*)
    │   ├── google-crc32c v1.7.1
    │   ├── google-resumable-media v2.7.2 (*)
    │   └── requests v2.32.5 (*)
    ├── google-genai v1.45.0
    │   ├── anyio v4.11.0
    │   │   ├── idna v3.11
    │   │   └── sniffio v1.3.1
    │   ├── google-auth v2.41.1 (*)
    │   ├── httpx v0.28.1
    │   │   ├── anyio v4.11.0 (*)
    │   │   ├── certifi v2025.10.5
    │   │   ├── httpcore v1.0.9
    │   │   │   ├── certifi v2025.10.5
    │   │   │   └── h11 v0.16.0
    │   │   └── idna v3.11
    │   ├── pydantic v2.12.3
    │   │   ├── annotated-types v0.7.0
    │   │   ├── pydantic-core v2.41.4
    │   │   │   └── typing-extensions v4.15.0
    │   │   ├── typing-extensions v4.15.0
    │   │   └── typing-inspection v0.4.2
    │   │       └── typing-extensions v4.15.0
    │   ├── requests v2.32.5 (*)
    │   ├── tenacity v9.1.2
    │   ├── typing-extensions v4.15.0
    │   └── websockets v15.0.1
    ├── packaging v25.0
    ├── proto-plus v1.26.1 (*)
    ├── protobuf v6.33.0
    ├── pydantic v2.12.3 (*)
    ├── shapely v2.1.2
    │   └── numpy v2.3.4
    └── typing-extensions v4.15.0
(*) Package tree already displayed
```

### Full fail log output
``` log
dummy-func     | info: Host.Triggers.Warmup[0]
dummy-func     |       Initializing Warmup Extension.
dummy-func     | dbug: Microsoft.Azure.WebJobs.Host.IDistributedLockManager[0]
dummy-func     |       Using BlobLeaseDistributedLockManager
dummy-func     | info: Host.Startup[503]
dummy-func     |       Initializing Host. OperationId: '3c162b91-152a-4b7d-8290-fd515a8341dc'.
dummy-func     | info: Host.Startup[504]
dummy-func     |       Host initialization: ConsecutiveErrors=0, StartupCount=1, OperationId=3c162b91-152a-4b7d-8290-fd515a8341dc
dummy-func     | dbug: Host.Startup[530]
dummy-func     |       {
dummy-func     |         "OriginalFunctionWorkerRuntime": "python",
dummy-func     |         "FunctionsWorkerRuntime": "python",
dummy-func     |         "OriginalFunctionWorkerRuntimeVersion": "3.13",
dummy-func     |         "FunctionsWorkerRuntimeVersion": "3.13",
dummy-func     |         "FunctionsExtensionVesion": null,
dummy-func     |         "HostDirectory": "/home/site/wwwroot",
dummy-func     |         "InStandbyMode": false,
dummy-func     |         "HasBeenSpecialized": false,
dummy-func     |         "UsePlaceholderDotNetIsolated": false,
dummy-func     |         "WebSiteSku": null,
dummy-func     |         "FeatureFlags": null,
dummy-func     |         "HostingConfig": {},
dummy-func     |         "HISMode": "Disabled"
dummy-func     |       }
dummy-func     | dbug: Microsoft.Extensions.Hosting.Internal.Host[1]
dummy-func     |       Hosting starting
dummy-func     | info: Microsoft.Azure.WebJobs.Hosting.OptionsLoggingService[0]
dummy-func     |       LoggerFilterOptions
dummy-func     |       {
dummy-func     |         "MinLevel": "None",
dummy-func     |         "Rules": [
dummy-func     |           {
dummy-func     |             "ProviderName": null,
dummy-func     |             "CategoryName": null,
dummy-func     |             "LogLevel": null,
dummy-func     |             "Filter": "<AddFilter>b__0"
dummy-func     |           },
dummy-func     |           {
dummy-func     |             "ProviderName": "Microsoft.Azure.WebJobs.Script.WebHost.Diagnostics.WebHostSystemLoggerProvider",
dummy-func     |             "CategoryName": null,
dummy-func     |             "LogLevel": "None",
dummy-func     |             "Filter": null
dummy-func     |           },
dummy-func     |           {
dummy-func     |             "ProviderName": "Microsoft.Azure.WebJobs.Script.WebHost.Diagnostics.WebHostSystemLoggerProvider",
dummy-func     |             "CategoryName": null,
dummy-func     |             "LogLevel": null,
dummy-func     |             "Filter": "<AddFilter>b__0"
dummy-func     |           },
dummy-func     |           {
dummy-func     |             "ProviderName": null,
dummy-func     |             "CategoryName": null,
dummy-func     |             "LogLevel": null,
dummy-func     |             "Filter": "<AddFilter>b__0"
dummy-func     |           },
dummy-func     |           {
dummy-func     |             "ProviderName": null,
dummy-func     |             "CategoryName": "Host.Results",
dummy-func     |             "LogLevel": "Debug",
dummy-func     |             "Filter": null
dummy-func     |           },
dummy-func     |           {
dummy-func     |             "ProviderName": null,
dummy-func     |             "CategoryName": "Host.Aggregator",
dummy-func     |             "LogLevel": "Trace",
dummy-func     |             "Filter": null
dummy-func     |           },
dummy-func     |           {
dummy-func     |             "ProviderName": null,
dummy-func     |             "CategoryName": "Function",
dummy-func     |             "LogLevel": "Debug",
dummy-func     |             "Filter": null
dummy-func     |           },
dummy-func     |           {
dummy-func     |             "ProviderName": null,
dummy-func     |             "CategoryName": null,
dummy-func     |             "LogLevel": "Debug",
dummy-func     |             "Filter": null
dummy-func     |           },
dummy-func     |           {
dummy-func     |             "ProviderName": null,
dummy-func     |             "CategoryName": "Host.Function.ToolingConsoleLog",
dummy-func     |             "LogLevel": "Information",
dummy-func     |             "Filter": null
dummy-func     |           },
dummy-func     |           {
dummy-func     |             "ProviderName": "Microsoft.Azure.WebJobs.Script.WebHost.Diagnostics.SystemLoggerProvider",
dummy-func     |             "CategoryName": null,
dummy-func     |             "LogLevel": "None",
dummy-func     |             "Filter": null
dummy-func     |           },
dummy-func     |           {
dummy-func     |             "ProviderName": "Microsoft.Azure.WebJobs.Script.WebHost.Diagnostics.SystemLoggerProvider",
dummy-func     |             "CategoryName": null,
dummy-func     |             "LogLevel": null,
dummy-func     |             "Filter": "<AddFilter>b__0"
dummy-func     |           }
dummy-func     |         ]
dummy-func     |       }
dummy-func     | info: Microsoft.Azure.WebJobs.Hosting.OptionsLoggingService[0]
dummy-func     |       HttpWorkerOptions
dummy-func     |       {
dummy-func     |         "Type": 0,
dummy-func     |         "Description": null,
dummy-func     |         "Arguments": null,
dummy-func     |         "Port": 0,
dummy-func     |         "EnableForwardingHttpRequest": false,
dummy-func     |         "EnableProxyingHttpRequest": false,
dummy-func     |         "InitializationTimeout": "00:00:30"
dummy-func     |       }
dummy-func     | info: Microsoft.Azure.WebJobs.Hosting.OptionsLoggingService[0]
dummy-func     |       FunctionResultAggregatorOptions
dummy-func     |       {
dummy-func     |         "BatchSize": 1000,
dummy-func     |         "FlushTimeout": "00:00:30",
dummy-func     |         "IsEnabled": true
dummy-func     |       }
dummy-func     | info: Microsoft.Azure.WebJobs.Hosting.OptionsLoggingService[0]
dummy-func     |       ConcurrencyOptions
dummy-func     |       {
dummy-func     |         "DynamicConcurrencyEnabled": false,
dummy-func     |         "MaximumFunctionConcurrency": 500,
dummy-func     |         "CPUThreshold": 0.8,
dummy-func     |         "SnapshotPersistenceEnabled": false
dummy-func     |       }
dummy-func     | info: Microsoft.Azure.WebJobs.Hosting.OptionsLoggingService[0]
dummy-func     |       SingletonOptions
dummy-func     |       {
dummy-func     |         "LockPeriod": "00:00:15",
dummy-func     |         "ListenerLockPeriod": "00:01:00",
dummy-func     |         "LockAcquisitionTimeout": "10675199.02:48:05.4775807",
dummy-func     |         "LockAcquisitionPollingInterval": "00:00:05",
dummy-func     |         "ListenerLockRecoveryPollingInterval": "00:01:00"
dummy-func     |       }
dummy-func     | info: Microsoft.Azure.WebJobs.Hosting.OptionsLoggingService[0]
dummy-func     |       ScaleOptions
dummy-func     |       {
dummy-func     |         "ScaleMetricsMaxAge": "00:02:00",
dummy-func     |         "ScaleMetricsSampleInterval": "00:00:10",
dummy-func     |         "MetricsPurgeEnabled": true,
dummy-func     |         "IsTargetScalingEnabled": true,
dummy-func     |         "IsRuntimeScalingEnabled": false
dummy-func     |       }
dummy-func     | info: Microsoft.Azure.WebJobs.Hosting.JobHostService[0]
dummy-func     |       Starting JobHost
dummy-func     | info: Host.Startup[401]
dummy-func     |       Starting Host (HostId=42419c677d44-2137340777, InstanceId=14205b6a-802d-47bd-a3ce-2b61fe723943, Version=4.1042.100.10, ProcessId=10, AppDomainId=1, InDebugMode=False, InDiagnosticMode=False, FunctionsExtensionVersion=(null))
dummy-func     | info: Host.Startup[314]
dummy-func     |       Loading functions metadata
dummy-func     | dbug: Microsoft.Azure.WebJobs.Script.Workers.Rpc.RpcFunctionInvocationDispatcher[0]
dummy-func     |       Handling WorkerErrorEvent for runtime:python, workerId:python. Failed with: Microsoft.Azure.WebJobs.Script.Workers.WorkerProcessExitException: python exited with code 139 (0x8B)
dummy-func     |        ---> System.Exception
dummy-func     |          --- End of inner exception stack trace ---
dummy-func     | dbug: Microsoft.Azure.WebJobs.Script.Workers.Rpc.RpcFunctionInvocationDispatcher[0]
dummy-func     |       Attempting to dispose webhost or jobhost channel for workerId: '98b7cf7b-502d-49c1-8739-195b21895722', runtime: 'python'
dummy-func     | dbug: Microsoft.Azure.WebJobs.Script.Workers.Rpc.RpcFunctionInvocationDispatcher[0]
dummy-func     |       No initialized worker channels for runtime 'python'. Delaying future invocations
dummy-func     | dbug: Microsoft.Azure.WebJobs.Script.Workers.Rpc.RpcFunctionInvocationDispatcher[0]
dummy-func     |       Restarting worker channel for runtime: 'python'
dummy-func     | fail: Microsoft.Azure.WebJobs.Script.Workers.Rpc.RpcFunctionInvocationDispatcher[0]
dummy-func     |       Exceeded language worker restart retry count for runtime:python. Shutting down and proactively recycling the Functions Host to recover
dummy-func     | info: Host.General[337]
dummy-func     |       Host lock lease acquired by instance ID '00000000000000000000000007FD746A'.
dummy-func     | dbug: Microsoft.Azure.WebJobs.Script.Workers.Rpc.RpcFunctionInvocationDispatcher[0]
dummy-func     |       Handling WorkerErrorEvent for runtime:python, workerId:python. Failed with: System.TimeoutException: The operation has timed out.
dummy-func     |          at Microsoft.Azure.WebJobs.Script.Grpc.GrpcWorkerChannel.PendingItem.OnTimeout() in /_/src/WebJobs.Script.Grpc/Channel/GrpcWorkerChannel.cs:line 1802
dummy-func     | dbug: Microsoft.Azure.WebJobs.Script.Workers.Rpc.RpcFunctionInvocationDispatcher[0]
dummy-func     |       Attempting to dispose webhost or jobhost channel for workerId: '98b7cf7b-502d-49c1-8739-195b21895722', runtime: 'python'
dummy-func     | dbug: Microsoft.Azure.WebJobs.Script.Workers.Rpc.RpcFunctionInvocationDispatcher[0]
dummy-func     |       Did not find WebHost or JobHost channel to dispose for workerId: '98b7cf7b-502d-49c1-8739-195b21895722', runtime: 'python'
dummy-func     | dbug: Microsoft.Azure.WebJobs.Script.Workers.Rpc.RpcFunctionInvocationDispatcher[0]
dummy-func     |       Skipping worker channel restart for errored worker runtime: 'python', current runtime: 'python', isWebHostChannel: 'False', isJobHostChannel: 'False'
dummy-func     | info: Host.Startup[326]
dummy-func     |       Reading functions metadata (Custom)
dummy-func     | info: Host.Startup[327]
dummy-func     |       0 functions found (Custom)
dummy-func     | info: Host.Startup[315]
dummy-func     |       0 functions loaded
dummy-func     | dbug: Host.Startup[419]
dummy-func     |       FUNCTIONS_WORKER_RUNTIME value: 'python'
dummy-func     | dbug: Host.Startup[404]
dummy-func     |       Adding Function descriptor provider for language python.
dummy-func     | dbug: Host.Startup[405]
dummy-func     |       Creating function descriptors.
dummy-func     | dbug: Host.Startup[406]
dummy-func     |       Function descriptors created.
dummy-func     | dbug: Microsoft.Azure.WebJobs.Script.Workers.Rpc.RpcFunctionInvocationDispatcher[0]
dummy-func     |       Placeholder mode is enabled: False
dummy-func     | dbug: Microsoft.Azure.WebJobs.Script.Workers.Rpc.RpcFunctionInvocationDispatcher[0]
dummy-func     |       RpcFunctionInvocationDispatcher received no functions
dummy-func     | info: Host.Startup[0]
dummy-func     |       Generating 0 job function(s)
dummy-func     | warn: Host.Startup[0]
dummy-func     |       No job functions found. Try making your job classes and methods public. If you're using binding extensions (e.g. Azure Storage, ServiceBus, Timers, etc.) make sure you've called the registration method for the extension(s) in your startup code (e.g. builder.AddAzureStorage(), builder.AddServiceBus(), builder.AddTimers(), etc.).
dummy-func     | info: Microsoft.Azure.WebJobs.Hosting.OptionsLoggingService[0]
dummy-func     |       HttpOptions
dummy-func     |       {
dummy-func     |         "DynamicThrottlesEnabled": false,
dummy-func     |         "EnableChunkedRequestBinding": false,
dummy-func     |         "MaxConcurrentRequests": -1,
dummy-func     |         "MaxOutstandingRequests": -1,
dummy-func     |         "RoutePrefix": "api"
dummy-func     |       }
dummy-func     | info: Microsoft.Azure.WebJobs.Script.WebHost.WebScriptHostHttpRoutesManager[0]
dummy-func     |       Initializing function HTTP routes
dummy-func     |       No HTTP routes mapped
dummy-func     |
dummy-func     | info: Host.Startup[412]
dummy-func     |       Host initialized (120509ms)
dummy-func     | info: Host.Startup[413]
dummy-func     |       Host started (120522ms)
dummy-func     | info: Host.Startup[0]
dummy-func     |       Job host started
dummy-func     | dbug: Host.Startup[0]
dummy-func     |       File event source initialized.
dummy-func     | dbug: Host.Startup[0]
dummy-func     |       Debug file watch initialized.
dummy-func     | dbug: Host.Startup[0]
dummy-func     |       Diagnostic file watch initialized.
dummy-func     | dbug: Microsoft.Extensions.Hosting.Internal.Host[2]
dummy-func     |       Hosting started
dummy-func     | Hosting environment: Production
dummy-func     | Content root path: /home/site/wwwroot
dummy-func     | Now listening on: http://[::]:80
dummy-func     | Application started. Press Ctrl+C to shut down.
dummy-func     | dbug: Microsoft.Extensions.Hosting.Internal.Host[3]
dummy-func     |       Hosting stopping
dummy-func     | dbug: Microsoft.Azure.WebJobs.Script.WebHost.FileMonitoringService[0]
dummy-func     |       Stopping file watchers.
dummy-func     | dbug: Microsoft.Azure.WebJobs.Script.Workers.Rpc.RpcFunctionInvocationDispatcher[0]
dummy-func     |       Waiting for RpcFunctionInvocationDispatcher to shutdown
dummy-func     | dbug: Microsoft.Azure.WebJobs.Script.Workers.Rpc.RpcFunctionInvocationDispatcher[0]
dummy-func     |       Draining invocations from language worker channel timed out. Shutting down 'RpcFunctionInvocationDispatcher'
dummy-func     | info: Microsoft.Azure.WebJobs.Hosting.JobHostService[0]
dummy-func     |       Stopping JobHost
dummy-func     | dbug: Host.Startup[415]
dummy-func     |       Stopping ScriptHost instance '14205b6a-802d-47bd-a3ce-2b61fe723943'.
dummy-func     | info: Host.Startup[0]
dummy-func     |       Job host stopped
dummy-func     | dbug: Host.Startup[416]
dummy-func     |       Stopped ScriptHost instance '14205b6a-802d-47bd-a3ce-2b61fe723943'.
dummy-func     | dbug: Microsoft.Extensions.Hosting.Internal.Host[4]
dummy-func     |       Hosting stopped
dummy-func     | dbug: Host.Startup[0]
dummy-func     |       Disposing ScriptHost.
dummy-func     | dbug: Host.Startup[417]
dummy-func     |       Disposing ScriptHost instance '14205b6a-802d-47bd-a3ce-2b61fe723943'.
dummy-func     | dbug: Microsoft.Azure.WebJobs.Script.Workers.Rpc.RpcFunctionInvocationDispatcher[0]
dummy-func     |       Disposing FunctionDispatcher
dummy-func     | dbug: Host.Startup[418]
dummy-func     |       Disposed ScriptHost instance '14205b6a-802d-47bd-a3ce-2b61fe723943'.
dummy-func     | dbug: Host.Startup[417]
dummy-func     |       Disposing ScriptHost instance '14205b6a-802d-47bd-a3ce-2b61fe723943'.
dummy-func     | dbug: Host.Startup[418]
dummy-func     |       Disposed ScriptHost instance '14205b6a-802d-47bd-a3ce-2b61fe723943'.
dummy-func     | dbug: Host.General[336]
dummy-func     |       Host instance '00000000000000000000000007FD746A' released lock lease.
dummy-func     | dbug: Host.Startup[417]
dummy-func     |       Disposing ScriptHost instance '14205b6a-802d-47bd-a3ce-2b61fe723943'.
dummy-func     | dbug: Host.Startup[418]
dummy-func     |       Disposed ScriptHost instance '14205b6a-802d-47bd-a3ce-2b61fe723943'.
dummy-func exited with code 0

```