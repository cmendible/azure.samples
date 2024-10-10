output "endpoint" {
  value = azapi_resource.apim.output.properties.gatewayUrl
}