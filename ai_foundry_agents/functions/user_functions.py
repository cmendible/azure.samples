import json
from azure.ai.agents import AgentsClient
from azure.ai.agents.models import FunctionTool, ToolSet
from typing import Set
from azure.ai.agents.telemetry import trace_function

@trace_function()
def get_lecture_schedule_options() -> str:
    """
    Get the alternatives for math class as a JSON array.

    :return: The math class alternatives in JSON format.
    :rtype: str
    """
    alternatives = [
        "Math 101 - Tuesday 10am",
        "Math 101 - Wednesday 2pm"
    ]

    alt_json = json.dumps(alternatives)
    return alt_json

def get_custom_tools(agents_client: AgentsClient) -> ToolSet:
    user_function_set: Set = {get_lecture_schedule_options}
    functions = FunctionTool(functions=user_function_set)
    toolset = ToolSet()
    toolset.add(functions)

    agents_client.enable_auto_function_calls(user_function_set)

    return toolset 