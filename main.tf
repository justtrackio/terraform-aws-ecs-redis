locals {
  container_definitions = "[${module.container_definition.json_map_encoded}]"
  default_policies = [
    "arn:aws:iam::aws:policy/CloudWatchFullAccessV2",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
  ]
  service_discovery_name = var.service_discovery_name == null ? "${module.this.name}.${module.this.stage}" : var.service_discovery_name
}

module "ecs_label" {
  source  = "justtrackio/label/null"
  version = "0.26.0"

  context     = module.this.context
  label_order = var.label_orders.ecs
}

resource "aws_cloudwatch_log_group" "default" {
  count = var.cloudwatch_log_group_enabled ? 1 : 0

  name              = module.this.id
  tags              = module.this.tags
  retention_in_days = var.cloudwatch_log_retention_in_days
}

module "container_definition" {
  source  = "cloudposse/ecs-container-definition/aws"
  version = "0.61.1"

  container_name               = var.container_name
  container_cpu                = var.container_cpu
  container_memory_reservation = var.container_memory_reservation
  container_image              = "${var.container_image_repository}:${var.container_image_tag}"

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

  log_configuration = {
    logDriver = "awslogs"
    options = {
      awslogs-group  = try(aws_cloudwatch_log_group.default[0].name, ""),
      awslogs-region = module.this.aws_region
    }
  }

  readonly_root_filesystem = true
}

moved {
  from = module.service.aws_ecs_service.this
  to   = module.service.aws_ecs_service.ignore_changes_task_definition
}

moved {
  from = module.service.aws_ecs_task_definition.this
  to   = module.service.aws_ecs_task_definition.default
}

moved {
  from = module.service.aws_iam_role.task_exec
  to   = module.service.aws_iam_role.ecs_exec
}

moved {
  from = module.service.aws_iam_role.tasks
  to   = module.service.aws_iam_role.ecs_task
}

moved {
  from = module.service.aws_ecs_service.ignore_changes_task_definition
  to   = module.ecs_service.aws_ecs_service.default
}

moved {
  from = module.service.aws_iam_role.ecs_exec
  to   = module.ecs_service.aws_iam_role.ecs_exec
}

moved {
  from = module.service.aws_iam_role.ecs_task
  to   = module.ecs_service.aws_iam_role.ecs_task
}

moved {
  from = module.service.aws_iam_role_policy_attachment.ecs_task
  to   = module.ecs_service.aws_iam_role_policy_attachment.ecs_task
}

moved {
  from = module.service.aws_iam_role_policy_attachment.ecs_exec
  to   = module.ecs_service.aws_iam_role_policy_attachment.ecs_exec
}

moved {
  from = module.service.aws_iam_role_policy.ecs_exec
  to   = module.ecs_service.aws_iam_role_policy.ecs_exec
}

moved {
  from = module.service.aws_ecs_task_definition.default
  to   = module.ecs_service.aws_ecs_task_definition.default
}

module "ecs_service" {
  source  = "justtrackio/ecs-alb-service-task/aws"
  version = "1.6.0"

  container_definition_json          = local.container_definitions
  deployment_maximum_percent         = var.deployment_maximum_percent
  deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent
  desired_count                      = 1
  ecs_cluster_arn                    = data.aws_ecs_cluster.default.arn
  ignore_changes_task_definition     = var.ignore_changes_task_definition
  wait_for_steady_state              = var.wait_for_steady_state
  launch_type                        = var.launch_type
  network_mode                       = var.network_mode
  service_placement_constraints      = var.service_placement_constraints
  task_cpu                           = var.task_cpu
  task_memory                        = var.task_memory
  service_registries = [{
    registry_arn   = aws_service_discovery_service.default.arn
    container_name = var.container_name
    container_port = 6379
  }]
  task_exec_policy_arns = local.default_policies
  task_policy_arns      = local.default_policies
  task_placement_constraints = length(var.service_placement_constraints) != 0 ? var.service_placement_constraints : module.this.environment == "prod" ? [{
    type       = "memberOf"
    expression = "attribute:spotinst.io/container-instance-lifecycle==od"
  }] : []
  vpc_id = "" # not needed, but can't be omitted

  label_orders = var.label_orders
  context      = module.this.context
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
