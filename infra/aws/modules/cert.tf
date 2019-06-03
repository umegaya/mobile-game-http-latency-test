resource "aws_route53_zone" "aws-module-cert-zone" {
  name = "${var.root_domain}"
}


resource "aws_acm_certificate" "aws-module-cert-certificate" {
  domain_name       = "${var.host_name_prefix}.${var.root_domain}"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "aws-module-cert-verification-dns-record" {
  zone_id = "${aws_route53_zone.aws-module-cert-certificate.zone_id}"
  name = "${aws_acm_certificate.aws-module-cert-certificate.domain_validation_options.0.resource_record_name}"
  type = "${aws_acm_certificate.aws-module-cert-certificate.domain_validation_options.0.resource_record_type}"
  records = ["${aws_acm_certificate.aws-module-cert-certificate.domain_validation_options.0.resource_record_value}"]
  ttl = "300"
}
