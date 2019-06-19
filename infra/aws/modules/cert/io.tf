variable "namespace" {
  type = string
}
variable "root_domain" {
  type = string
}
variable "cn_lb_mapping" {
  type = list(map(string))
}


output "certificates" {
  value = [for c in aws_acm_certificate.aws-module-cert-certificate: c.arn]
}
output "zone_id" {
  value = "${data.aws_route53_zone.aws-module-cert-root-domain.zone_id}"
}
output "domain_names" {
  value = [for c in aws_acm_certificate.aws-module-cert-certificate: c.domain_name]
}