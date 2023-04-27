variable "container_cpu" {
  type        = number
  description = "The number of cpu units to reserve for the container. This is optional for tasks using Fargate launch type and the total amount of container_cpu of all containers in a task will need to be lower than the task-level cpu value"
  default     = 25
}

variable "container_image_repository" {
  type        = string
  description = "The image repository used to start the container. Images in the Docker Hub registry available by default"
  default     = "redis"
}

variable "container_image_tag" {
  type        = string
  description = "The image tag used to start the container. Images in the Docker Hub registry available by default"
  default     = "7-alpine"
}

variable "container_memory_reservation" {
  type        = number
  description = "The amount of memory (in MiB) to reserve for the container. If container needs to exceed this threshold, it can do so up to the set container_memory hard limit"
  default     = 50
}

variable "container_name" {
  type        = string
  description = "The name of the container. Up to 255 characters ([a-z], [A-Z], [0-9], -, _ allowed)"
  default     = "redis"
}

variable "deployment_maximum_percent" {
  type        = number
  description = "The upper limit of the number of tasks (as a percentage of `desired_count`) that can be running in a service during a deployment"
  default     = 100
}

variable "deployment_minimum_healthy_percent" {
  type        = number
  description = "The lower limit (as a percentage of `desired_count`) of the number of tasks that must remain running and healthy in a service during a deployment"
  default     = 0
}

variable "ecs_cluster_arn" {
  type        = string
  description = "The ARN of the ECS cluster where service will be provisioned"
}

variable "launch_type" {
  type        = string
  description = "The launch type on which to run your service. Valid values are `EC2` and `FARGATE`"
  default     = "EC2"
}

variable "network_mode" {
  type        = string
  description = "The network mode to use for the task. This is required to be `awsvpc` for `FARGATE` `launch_type` or `null` for `EC2` `launch_type`"
  default     = null
}

variable "redis_maxmemory" {
  type        = number
  description = "Maxmemory is a Redis configuration that allows you to set the memory limit at which your eviction policy takes effect."
  default     = 25
}

variable "service_discovery_name" {
  type        = string
  description = "The name of the service."
}

variable "service_discovery_namespace_id" {
  type        = string
  description = "The ID of the namespace that you want to use to create the service."
}

variable "service_placement_constraints" {
  type = list(object({
    type       = string
    expression = string
  }))
  description = "The rules that are taken into consideration during task placement. Maximum number of placement_constraints is 10. See [`placement_constraints`](https://www.terraform.io/docs/providers/aws/r/ecs_service.html#placement_constraints-1) docs"
  default     = []
}

variable "vpc_id" {
  type        = string
  description = "The VPC ID where resources are created"
}
