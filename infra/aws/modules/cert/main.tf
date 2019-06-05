data "aws_route53_zone" "aws-module-cert-root-domain" {
  name         = "${var.root_domain}."
}

resource "aws_acm_certificate" "aws-module-cert-certificate" {
  count          = "${length(var.cn_lb_mapping)}"
  domain_name    = "${var.cn_lb_mapping[count.index].cn}.${var.root_domain}"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "aws-module-cert-verification-dns-record" {
  count = "${length(aws_acm_certificate.aws-module-cert-certificate)}"
  zone_id = "${data.aws_route53_zone.aws-module-cert-root-domain.zone_id}"
  name = "${aws_acm_certificate.aws-module-cert-certificate[count.index].domain_validation_options.0.resource_record_name}"
  type = "${aws_acm_certificate.aws-module-cert-certificate[count.index].domain_validation_options.0.resource_record_type}"
  records = ["${aws_acm_certificate.aws-module-cert-certificate[count.index].domain_validation_options.0.resource_record_value}"]
  ttl = "300"
}

resource "aws_route53_record" "aws-module-cert-lb-dns-record" {
  count   = "${length(var.cn_lb_mapping)}"
  zone_id = "${data.aws_route53_zone.aws-module-cert-root-domain.zone_id}"
  name    = "${var.cn_lb_mapping[count.index].cn}.${var.root_domain}"
  type    = "CNAME"
  ttl     = "3600"
  records = ["${var.cn_lb_mapping[count.index].dns}"]
}
