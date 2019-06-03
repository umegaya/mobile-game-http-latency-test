variable "namespace" {
  type = string
}
variable "root_domain" {
  type = string
}
variable "host_name_prefix" {
  type = string
}
variable "lb_dns_name" {
  type = string
}


output "certificate_arn" {
  value = "${aws_acm_certificate.aws-module-cert-certificate.arn}"
}
output "zone_id" {
  value = "${data.aws_route53_zone.aws-module-cert-root-domain.zone_id}"
}