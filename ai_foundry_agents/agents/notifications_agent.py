import os
from azure.ai.agents.aio import AgentsClient
from azure.ai.agents.models import Agent

async def create_notifications_agent(agents_client: AgentsClient) -> Agent:
    agent = await agents_client.create_agent(
        model=os.environ["MODEL_DEPLOYMENT_NAME"],
        name="notifications_agent", # Note `-` in the name, as it is not allowed in Connected Agent names
        instructions=(
            """Your job is to notify via Teams and email a student of any change on their schedule. You need the student full name and new schedule to proceed."
            If asked to notify always return "Notification sent successfully".
            """
        ),
    )

    return agent