locals {
  service_discovery_name = var.service_discovery_name == null ? "${module.this.name}.${module.this.stage}" : var.service_discovery_name
}

module "ecs_label" {
  source  = "justtrackio/label/null"
  version = "0.26.0"

  context     = module.this.context
  label_order = var.label_orders.ecs
}

module "service" {
  source  = "terraform-aws-modules/ecs/aws//modules/service"
  version = "5.11.1"

  name                               = module.ecs_label.id
  cluster_arn                        = data.aws_ecs_cluster.default.arn
  cpu                                = null
  memory                             = null
  deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent
  deployment_maximum_percent         = var.deployment_maximum_percent
  launch_type                        = var.launch_type
  network_mode                       = var.network_mode
  enable_autoscaling                 = false

  security_group_use_name_prefix     = false
  iam_role_use_name_prefix           = false
  task_exec_iam_role_use_name_prefix = false
  tasks_iam_role_use_name_prefix     = false

  security_group_name     = module.this.id
  iam_role_name           = module.this.id
  task_exec_iam_role_name = "${module.this.id}-exec"
  tasks_iam_role_name     = "${module.this.id}-task"

  service_registries = {
    registry_arn   = aws_service_discovery_service.default.arn
    container_name = var.container_name
    container_port = 6379
  }

  tags = module.this.tags

  placement_constraints = length(var.service_placement_constraints) != 0 ? var.service_placement_constraints : module.this.environment == "prod" ? [{
    type       = "memberOf"
    expression = "attribute:spotinst.io/container-instance-lifecycle==od"
  }] : []

  container_definitions = {
    redis = {
      name               = var.container_name
      cpu                = var.container_cpu
      memory_reservation = var.container_memory_reservation
      image              = "${var.container_image_repository}:${var.container_image_tag}"

      port_mappings = [
        {
          name          = "redis"
          containerPort = 6379
          protocol      = "tcp"
        }
      ]

      command = [
        "--maxmemory ${var.redis_maxmemory}mb",
        "--maxmemory-policy ${var.redis_maxmemory_policy}"
      ]
    }
  }

  requires_compatibilities = []
  runtime_platform         = {}
}

resource "aws_service_discovery_service" "default" {
  name = local.service_discovery_name

  dns_config {
    namespace_id = data.aws_service_discovery_dns_namespace.default.id

    dns_records {
      ttl  = 60
      type = "SRV"
    }
  }

  health_check_custom_config {
    failure_threshold = 1
  }

  tags = module.this.tags
}
