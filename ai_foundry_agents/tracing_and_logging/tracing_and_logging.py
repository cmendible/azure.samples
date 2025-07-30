import logging
from opentelemetry import trace
from azure.ai.projects.aio import AIProjectClient
from azure.ai.agents.telemetry import AIAgentsInstrumentor
from azure.monitor.opentelemetry import configure_azure_monitor

async def start_tracing_logging(project_client: AIProjectClient) -> trace.Tracer:
    """
    Initializes OpenTelemetry tracing with a console exporter and setups logging levels.
    """

    # Suppress Azure SDK HTTP logging
    logging.getLogger("azure.core.pipeline.policies.http_logging_policy").setLevel(logging.WARNING)

    # Suppress aiohttp logging if needed
    logging.getLogger("aiohttp").setLevel(logging.WARNING)
    
    connection_string = await project_client.telemetry.get_application_insights_connection_string()
    configure_azure_monitor(connection_string=connection_string) #enable telemetry collection

    tracer = trace.get_tracer(__name__)

    # AZURE_TRACING_GEN_AI_CONTENT_RECORDING_ENABLED="true" in .env to enable content recording
    AIAgentsInstrumentor().instrument()

    return tracer
