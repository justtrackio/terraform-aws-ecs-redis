data "aws_ecs_cluster" "default" {
  cluster_name = module.this.environment
}

data "aws_service_discovery_dns_namespace" "default" {
  name = "${module.this.environment}.${module.this.namespace}"
  type = "DNS_PRIVATE"
}
