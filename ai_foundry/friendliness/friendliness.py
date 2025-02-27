import os
import json
from promptflow.core import Prompty
from promptflow.core import AzureOpenAIModelConfiguration

class FriendlinessEvaluator:
    def __init__(self, configuration: AzureOpenAIModelConfiguration):
        current_dir = os.path.dirname(__file__)
        prompty_path = os.path.join(current_dir, "friendliness.prompty")

       
        override_model = {"configuration": configuration, "parameters": {"max_tokens": 512}}

        self.prompty = Prompty.load(source=prompty_path, model=override_model)

    def __call__(self, *, response: str, **kwargs):
        llm_response = self.prompty(response=response)
        try:
            response = json.loads(llm_response)
        except Exception as ex:
            response = llm_response
        return response