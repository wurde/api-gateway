# Kubernetes supports multiple virtual clusters backed
# by the same physical cluster. These virtual clusters
# are called namespaces.
#
# https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/
# https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace
#
resource "kubernetes_namespace" "main" {
  metadata {
    name = "main"
  }
}

# A Persistent Volume (PV). They have a lifecycle
# independent of any individual pod that uses the PV.
# https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/persistent_volume
resource "kubernetes_persistent_volume" "krakend_config" {
  metadata {
    name = "krakend-config"
  }
  spec {
    # https://github.com/kubernetes/community/blob/master/contributors/design-proposals/scheduling/resources.md
    capacity = {
      storage = "64Mi"
    }
    access_modes = ["ReadWriteMany"]
    persistent_volume_source {
      aws_elastic_block_store {
        # Unique ID of the persistent disk resource in AWS.
        volume_id = ""
        # Filesystem type of the target volume.
        # Examples: "ext4", "xfs", "ntfs".
        fs_type = "ext4"
      }
    }
  }
}

# A Deployment provides declarative updates for Pods and
# ReplicaSets. If there are too many pods, it will kill
# some. If there are too few, the it will start more.
#
# https://kubernetes.io/docs/concepts/workloads/controllers/deployment/
# https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/deployment
#
resource "kubernetes_deployment" "api_gateway" {
  # (Required) Deployment metadata.
  # https://github.com/kubernetes/community/blob/master/contributors/devel/sig-architecture/api-conventions.md#metadata
  metadata {
    name  = local.app_name

    # A DNS compatible label that objects are subdivided into.
    namespace = local.namespace_name

    # A map of string keys and values that can be used to
    # organize and categorize objects.
    #
    # https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/
    #
    labels = {
      environment = var.environment
    }
  }
  spec {
    replicas = var.replicas
    selector {
      match_labels = {
        app = local.app_name
      }
    }
    template {
      # (Required) Service metadata.
      # https://github.com/kubernetes/community/blob/master/contributors/devel/sig-architecture/api-conventions.md#metadata
      metadata {
        labels = {
          app = local.app_name
        }
      }
      spec {
        container {
          image = local.container_image
          name  = local.app_name

          env {
            name  = "ENVIRONMENT"
            value = var.environment
          }

          port {
            container_port = 8080
          }

          # TODO
          #resources {
          #  # The min amount of resources required.
          #  requests {
          #    # 1/1000th of a CPU core.
          #    cpu    = "250m"
          #    memory = "256Mi"
          #  }
          #  # The max amount of resources allowed.
          #  limits {
          #    # 1/1000th of a CPU core.
          #    cpu    = "250m"
          #    memory = "256Mi"
          #  }
          #}

          # Indicates whether the container is running.
          # If the liveness probe fails, the kubelet
          # kills the container, and the container is
          # subjected to its restart policy.
          # TODO
          #liveness_probe {
          #  http_get {
          #    path = "/liveness"
          #    port = 80
          #
          #    http_header {
          #      name  = "X-Custom-Header"
          #      value = "Awesome"
          #    }
          #  }
          #
          #  initial_delay_seconds = 3
          #  period_seconds        = 3
          #}
          # Indicates whether the container is ready
          # to respond to requests. If the readiness
          # probe fails, the endpoints controller
          # removes the Pod's IP address from the
          # endpoints of all Services that match the
          # Pod.
          #readiness_probe {
          #  http_get {
          #    path = "/readiness"
          #    port = 80
          #  }
          #
          #  initial_delay_seconds = 5
          #  failure_threshold     = 3
          #  period_seconds        = 5
          #}

          # TODO
          volume_mount {
            mount_path = "/etc/krakend"
            read_only  = true

            name = kubernetes_persistent_volume.krakend_config.uid
          }
        }

        #dns_config {
        #  nameservers = ["1.1.1.1", "8.8.8.8", "9.9.9.9"]
        #  searches    = ["example.com"]
        #
        #  option {
        #    name  = "ndots"
        #    value = 1
        #  }
        #
        #  option {
        #    name = "use-vc"
        #  }
        #}
        #
        #dns_policy = "None"
      }

      # (default) Always, OnFailure, or Never.
      # https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#restartpolicy
      restart_policy = "OnFailure"
    }
  }
}

# An abstract way to expose an application running on a set
# of Pods as a network service.
#
# https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/service
# https://kubernetes.io/docs/concepts/services-networking/service/
#
resource "kubernetes_service" "api_gateway" {
  # (Required) Service metadata.
  # https://github.com/kubernetes/community/blob/master/contributors/devel/sig-architecture/api-conventions.md#metadata
  metadata {
    name = local.app_name

    # A DNS compatible label that objects are subdivided into.
    namespace = local.namespace_name

    # A map of string keys and values that can be used to
    # organize and categorize objects.
    #
    # https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/
    #
    labels {
      environment = var.environment
    }
  }
  strategy {
    # (default) RollingUpdate, Recreate
    type = "RollingUpdate"
    rolling_update {
      # Max number of pods that can be scheduled above desired number.
      max_surge = "0"

      # Max number of pods that can be unavailable.
      max_unavailable = "50%"
    }
  }
  spec {
    selector = {
      app = local.app_name
    }
    session_affinity = "ClientIP"
    port {
      port        = 8080
      target_port = 80
    }

    type = "LoadBalancer"
  }
}
