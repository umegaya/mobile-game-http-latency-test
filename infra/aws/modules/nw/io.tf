variable "namespace" {
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
output "subnets" {
  value = aws_subnet.aws-module-nw-subnet
}
