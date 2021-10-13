locals {
  app_name = "api-gateway"

  # https://registry.hub.docker.com/r/devopsfaith/krakend
  container_image = "devopsfaith/krakend:1.4.1"

  # namespace_name = data.kubernetes_namespace.main.metadata.0.name
}
