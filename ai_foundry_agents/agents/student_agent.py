import os
from azure.ai.agents.aio import AgentsClient
from azure.ai.agents.models import Agent

async def create_students_data_agent(agents_client: AgentsClient) -> Agent:
    agent = await agents_client.create_agent(
        model=os.environ["MODEL_DEPLOYMENT_NAME"],
        name="student_data_agent", # Note `-` in the name, as it is not allowed in Connected Agent names
        instructions=(
            """Your job is to rerieve or update the lecture schedule of a student. You need the student full name to proceed."
            If asked to retrieve always return Math: Mon, Wed, Fri 10:00-11:00, Physics: Tue, Thu 12:00-13:00 in JSON format.
            If asked to update the schedule, always return schedule "updated successfully".
            """
        ),
    )

    return agent