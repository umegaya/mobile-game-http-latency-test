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
variable "service_role_arn" {
  type = string
}
variable "container_name" {
  type = string
}
variable "container_forwarded_port" {
  type = number
}
variable "scheduling_strategy" {
  type = string
  default = "DAEMON"
}
variable "task_network_mode" {
  type = "string"
  default = "host"
}
variable "ecs_cluster_id" {
  type = string
}