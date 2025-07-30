# Lecture Change Orchestration Sample

This sample demonstrates how to orchestrate two agents using Azure AI Agent Service and its Python SDK for a university scenario.

## Use Case

A university alumn wants to change a lecture because it doesn't fit their schedule. The process involves:
- Gathering the student's request 
- Finding alternative lectures
- Updating the schedule

## Agents

- **OrchestratorAgent**: Handles alumn interaction and request validation
- **StudentDataAgent**: Finds alternative lectures and processes the change
- **ScheduleAgent**: Finds alternative lectures and processes the change
- **NotificationsAgent**: Notifies the student of the change via Teams and email

## What features does this sample include?

- **Multi-agent orchestration**: The sample shows how to orchestrate multiple agents to complete a task.
- **Agent communication**: Demonstrates how agents can communicate with each other to share information and complete tasks.
- **Function calling**: The sample uses function calling to allow agents to execute specific tasks.
- **Agents, Runs and Threads**: Best practices for managing agents, runs, and threads.
- **Tracing and Logging**: The sample includes tracing to monitor the flow of requests and responses between agents.

## Requirements
- Python 3.8+
- Azure AI Agent Python SDK

## Setup

1. Install dependencies:
   ```bash
   python3 -m venv .venv
   source .venv/bin/activate
   pip install -r requirements.txt
   ```
2. Configure your Azure credentials as required by the SDK.

## Environment Variables

Create and .env file with the following content:

```env
PROJECT_ENDPOINT=<your_project_endpoint>
MODEL_DEPLOYMENT_NAME=<your_model_deployment_name>
OTEL_SERVICE_NAME="Student Schedule Agent"
```

If you want add AI content recording add the following variables to your .env file:

```env
AZURE_TRACING_GEN_AI_CONTENT_RECORDING_ENABLED="true"
```

## Start the Application

```bash
source .venv/bin/activate
chainlit run main.py -w --port 8001
```
