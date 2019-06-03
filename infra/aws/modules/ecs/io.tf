variable "namespace" {
  type = string
}
variable "ecs_launch_type" {
  type = string
}
variable "lb_target_group_arn" {
  type = string  
}
variable "container_definitions" {
  type = string
}

output "cluster_name" {
  value = "${aws_ecs_cluster.aws-module-ecs-cluster.name}"
}