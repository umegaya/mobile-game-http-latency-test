variable "namespace" {
  type = string
}
variable "lb_type" {
  type = string
}
variable "vpc_cidr_block" {
  type = string  
}
variable "subnet_count" {
  type = number
}
variable "blacklisted_zones" {
  type = list(string)
}


output "vpc_id" {
  value = "${aws_vpc.aws-module-nw-vpc.id}"
}
output "instance_security_group" {
  value = "${aws_security_group.aws-module-nw-instance-security-group.id}"
}
output "subnets" {
  value = aws_subnet.aws-module-nw-subnet
}
output "dns_name" {
  value = "${aws_lb.aws-module-nw-lb.dns_name}"
}
output "arn" {
  value = "${aws_lb.aws-module-nw-lb.arn}"
}