import asyncio
import os
import chainlit as cl
from azure.ai.projects.aio import AIProjectClient
from azure.ai.agents.models import ListSortOrder, ConnectedAgentTool, ConnectedAgentToolDefinition
from azure.identity.aio import DefaultAzureCredential
from dotenv import load_dotenv
from typing import List
from agents.notifications_agent import create_notifications_agent
from agents.schedule_agent import create_schedule_agent
from agents.student_agent import create_students_data_agent
from agents.orchestrator import create_orchestrtor_agent
from tracing_and_logging.tracing_and_logging import start_tracing_logging
from functions.user_functions import get_custom_tools

def get_project_client() -> AIProjectClient:
    credential = DefaultAzureCredential()
    project_client = AIProjectClient(
        credential=credential, 
        endpoint=os.environ["PROJECT_ENDPOINT"],
    )
    return project_client

load_dotenv()

project_client = get_project_client()

tracer = asyncio.run(start_tracing_logging(project_client))

agents: List[ConnectedAgentToolDefinition]

@tracer.start_as_current_span(__file__)
@cl.on_chat_start
async def start():
    global agent_id
    global agents_client
    global agents
    global thread

    agents_client = project_client.agents
    
    # Combine custom local tools
    toolset = get_custom_tools(agents_client)

    schedule_agent = await create_schedule_agent(agents_client)
    student_agent = await create_students_data_agent(agents_client)
    notifications_agent = await create_notifications_agent(agents_client)

    # Initialize Connected Agent tools with the agent id, name, and description
    agents = ConnectedAgentTool(
        id=schedule_agent.id, name=schedule_agent.name, description="Gets the schedule for a given lecture",
    ).definitions

    agents.extend(ConnectedAgentTool(
        id=student_agent.id, name=student_agent.name, description="Gets or updates the lecture schedule of a student",
    ).definitions)

    agents.extend(ConnectedAgentTool(
        id=notifications_agent.id, name=notifications_agent.name, description="Notifies a student of any change on their schedule",
    ).definitions)

    # Create agent with the Connected Agent tool and process assistant run
    agent = await create_orchestrtor_agent(agents_client, agents)

    agent_id = agent.id
    print(f"Created agent, agent ID: {agent_id}")

    thread = await agents_client.threads.create()
    print(f"Created thread, thread ID: {thread.id}")

    # sleep 3 seconds to ensure the agent is ready
    await asyncio.sleep(1)

@tracer.start_as_current_span(__file__)
@cl.on_message
async def main(message: cl.Message):
    cl_msg = cl.Message(content="")
    await cl_msg.send()
    await cl_msg.stream_token(" ")

    message = await agents_client.messages.create(thread_id=thread.id, role="user", content=message.content)
    print(f"Created message, message ID: {message.id}")

    run = await agents_client.runs.create_and_process(thread_id=thread.id, agent_id=agent_id)
    print(f"Run completed with status: {run.status}")

    messages = agents_client.messages.list(thread_id=thread.id, order=ListSortOrder.ASCENDING)
    last_msg = None
    async for msg in messages:
        if msg.text_messages:
            last_msg = msg
    if last_msg:
        last_text = last_msg.text_messages[-1]
        print(f"{last_msg.role}: {last_text.text.value}")

        await cl_msg.stream_token(last_text.text.value)
        await cl_msg.update()

@tracer.start_as_current_span(__file__)
@cl.on_app_shutdown
async def stop():
    await agents_client.delete_agent(agent_id=agent_id)
    print(f"Agent {agent_id} deleted.")

    for ct in agents:
        await agents_client.delete_agent(ct.connected_agent.id)
        print(f"Child Agent {ct.connected_agent.id} deleted.")
