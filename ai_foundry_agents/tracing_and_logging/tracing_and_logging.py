import logging
from azure.core.settings import settings
settings.tracing_implementation = "opentelemetry" #Required for async tracing with OpenTelemetry. Othewise you'll get an await error.
from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import SimpleSpanProcessor, ConsoleSpanExporter
from azure.ai.agents.telemetry import AIAgentsInstrumentor

def start_tracing_logging() -> trace.Tracer:
    """
    Initializes OpenTelemetry tracing with a console exporter and setups logging levels.
    """

    # Suppress Azure SDK HTTP logging
    logging.getLogger("azure.core.pipeline.policies.http_logging_policy").setLevel(logging.WARNING)

    # Suppress aiohttp logging if needed
    logging.getLogger("aiohttp").setLevel(logging.WARNING)

    # Setup tracing to console
    # Requires opentelemetry-sdk
    span_exporter = ConsoleSpanExporter()
    tracer_provider = TracerProvider()
    tracer_provider.add_span_processor(SimpleSpanProcessor(span_exporter))
    trace.set_tracer_provider(tracer_provider)
    tracer = trace.get_tracer(__name__)

    AIAgentsInstrumentor().instrument()

    return tracer
