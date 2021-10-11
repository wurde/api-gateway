# https://registry.terraform.io/providers/hashicorp/kubernetes
provider "kubernetes" {
  config_path = var.kubeconfig_path
}
