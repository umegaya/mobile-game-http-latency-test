/*resource "aws_acm_certificate" "latency-research-http2" {
  domain_name       = "elb.amazonaws.com"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "example_acm_public" {
  count = "${length(aws_acm_certificate.latency-research-http2.domain_validation_options)}"
  zone_id = "${var.example_zone_id}"
  name = "${lookup(aws_acm_certificate.latency-research-http2.domain_validation_options[count.index],"resource_record_name")}"
  type = "${lookup(aws_acm_certificate.latency-research-http2.domain_validation_options[count.index],"resource_record_type")}"
  ttl = "300"
  records = ["${lookup(aws_acm_certificate.latency-research-http2.domain_validation_options[count.index],"resource_record_value")}"]
}
*/
