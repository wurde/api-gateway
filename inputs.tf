variable "kubeconfig_path" {
  description = "Path to the Kubeconfig."
  type        = string
}

variable "krakend_config_path" {
  description = "Path to the KrakenD configuration."
  type        = string
}

variable "replicas" {
  description = "The number of desired replicas. Defaults to 2."
  type        = number
  default     = 2
}

variable "environment" {
  description = "The target environment."
  type        = string
  default     = "development"
}
