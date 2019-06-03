variable "namespace" {
  type = string
}
variable "key_pair_cert" {
  type = string
}
variable "root_domain" {
  type = string  
}
variable "instance_type" {
  type = string
}
variable "min_instance_size" {
  type = number
}
variable "max_instance_size" {
  type = number  
}
variable "desired_instance_capacity" {
  type = number  
}
variable "security_groups" {
  type = list(string)
}
variable "vpc_zone_identifier" {
  type = list(string)
}
variable "ecs_cluster_name" {
  type = string
}
variable "cpu_utilization_threshold" {
  type = number
}


output "autoscaling_group_name" {
  value = "${aws_autoscaling_group.aws-module-ec2-autoscaling-group.id}"
}
