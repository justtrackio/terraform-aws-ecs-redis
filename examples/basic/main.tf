module "redis" {
  source = "./../.."

  ecs_cluster_arn                = "your-ecs-cluster"
  service_discovery_name         = "redis"
  service_discovery_namespace_id = "ns-0000000000000000"
  vpc_id                         = "vpc-00000000000000000"
}
