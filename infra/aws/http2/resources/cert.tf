resource "aws_route53_zone" "latency-research-http2" {
  name = "${var.root_domain}"
}


resource "aws_acm_certificate" "latency-research-http2" {
  domain_name       = "latency-research-http2.service.${var.root_domain}"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "latency-research-http2" {
  zone_id = "${aws_route53_zone.latency-research-http2.zone_id}"
  name = "${aws_acm_certificate.latency-research-http2.domain_validation_options.0.resource_record_name}"
  type = "${aws_acm_certificate.latency-research-http2.domain_validation_options.0.resource_record_type}"
  records = ["${aws_acm_certificate.latency-research-http2.domain_validation_options.0.resource_record_value}"]
  ttl = "300"
}

resource "aws_key_pair" "latency-research-http2" {
  key_name   = "latency-research-http2-key-pair"
  public_key = "${data.local_file.latency-research-http2-cert.content}"
}
