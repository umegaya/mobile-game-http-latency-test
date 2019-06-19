variable "namespace" {
  type = string
}
variable "lb_type" {
  type = string
}
variable "vpc_id" {
  type = string
}
variable "served_ports" {
  type = list(number)
}
variable "target_group_ports" {
  type = list(number)
  default = [0]
}
variable "subnets" {
  type = list(string)
}
variable "protocol" {
  type = string
}
variable "inner_protocol" {
  type = string
  default = ""
}
variable "certificate_arn" {
  type = string
}


output "dns_name" {
  value = "${aws_lb.aws-module-lb-lb.dns_name}"
}
output "target_group_arns" {
  value = [for tg in aws_lb_target_group.aws-module-lb-target-group: tg.arn]
}
output "listener_arns" {
  value = concat(
    [for l in aws_lb_listener.aws-module-lb-alb-listener: l.arn],
    [for l in aws_lb_listener.aws-module-lb-nlb-listener: l.arn]
  )
}
