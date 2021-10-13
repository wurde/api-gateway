# https://www.terraform.io/docs/language/settings/index.html
# Configure some behaviors of Terraform itself.
terraform {
  # Specify which versions of Terraform can be used with this configuration.
  required_version = "~> v1.1"

  required_providers {
    # https://registry.terraform.io/providers/hashicorp/kubernetes
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.5"
    }

    # https://registry.terraform.io/providers/hashicorp/null
    null = {
      source  = "hashicorp/null"
      version = "~> 3.1"
    }
  }
}
