import os
from azure.ai.agents.aio import AgentsClient
from azure.ai.agents.models import Agent

async def create_schedule_agent(agents_client: AgentsClient) -> Agent:
    stock_price_agent = await agents_client.create_agent(
        model=os.environ["MODEL_DEPLOYMENT_NAME"],
        name="schedule_agent",  # Note `-` in the name, as it is not allowed in Connected Agent names
        instructions=(
            """Your job is to get the available schedules for a given lecture. 
            If asked to retrieve always return Math: Option 1 Mon, Wed, Fri 10:00-11:00 | Option 2 Mon, Wed, Fri 15:00-16:00, Physics: Option 1 Tue, Thu 12:00-13:00 | Option 2 Tue, Thu 18:00-19:00 in JSON format.
            """
        ),
    )
    return stock_price_agent
