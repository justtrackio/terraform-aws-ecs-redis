module "container_definition" {
  count   = module.this.enabled ? 1 : 0
  source  = "cloudposse/ecs-container-definition/aws"
  version = "0.58.3"

  container_image              = "${var.container_image_repository}:${var.container_image_tag}"
  container_name               = var.container_name
  container_cpu                = var.container_cpu
  container_memory_reservation = var.container_memory_reservation

  port_mappings = [
    {
      containerPort = 6379
      hostPort      = 0
      protocol      = "tcp"
    },
  ]

  command = [
    "--maxmemory ${var.redis_maxmemory}mb",
    "--maxmemory-policy ${var.redis_maxmemory_policy}"
  ]
}

module "redis" {
  count   = module.this.enabled ? 1 : 0
  source  = "cloudposse/ecs-alb-service-task/aws"
  version = "0.68.0"

  context = module.this.context

  container_definition_json          = "[${sensitive(module.container_definition[0].json_map_encoded)}]"
  deployment_maximum_percent         = var.deployment_maximum_percent
  deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent
  ecs_cluster_arn                    = var.ecs_cluster_arn
  launch_type                        = var.launch_type
  network_mode                       = var.network_mode
  vpc_id                             = var.vpc_id

  service_registries = [{
    registry_arn   = aws_service_discovery_service.default[0].arn
    container_name = var.container_name
    container_port = 6379
  }]

  tags = module.this.tags

  service_placement_constraints = length(var.service_placement_constraints) != 0 ? var.service_placement_constraints : module.this.environment == "prod" ? [{
    type       = "memberOf"
    expression = "attribute:spotinst.io/container-instance-lifecycle==od"
  }] : []
}

resource "aws_service_discovery_service" "default" {
  count = module.this.enabled ? 1 : 0
  name  = var.service_discovery_name

  dns_config {
    namespace_id = var.service_discovery_namespace_id

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
