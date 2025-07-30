import os
from azure.ai.agents.aio import AgentsClient
from azure.ai.agents.models import Agent, ConnectedAgentToolDefinition
from typing import List

async def create_orchestrtor_agent(agents_client: AgentsClient, agents: List[ConnectedAgentToolDefinition]) -> Agent:
     # Create agent with the Connected Agent tool and process assistant run
    agent = await agents_client.create_agent(
        model=os.environ["MODEL_DEPLOYMENT_NAME"],
        name="my-assistant",
        instructions="""You are a helpful assistant that can:
        1. Help a Student get their lecture schedule
        2. Process lecture change requests
        3. Notify students about lecture changes
        """,
        tools=agents,
    )

    return agent
