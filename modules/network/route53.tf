
data "aws_route53_zone" "selected" {
  name         = local.root_domain
  private_zone = false
}

resource "aws_route53_record" "skc2" {
  zone_id = "${data.aws_route53_zone.selected.zone_id}"
  name    = local.base_domain
  type    = "A"

  alias {
      name = "${aws_lb.main.dns_name}"
      zone_id = "${aws_lb.main.zone_id}"
      evaluate_target_health = true
  }
}


resource "aws_acm_certificate" "default" {
  domain_name       = local.base_domain
  validation_method = "DNS"

  tags = {
    Environment = "skc2"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "validation" {
  name    = "${aws_acm_certificate.default.domain_validation_options.0.resource_record_name}"
  type    = "${aws_acm_certificate.default.domain_validation_options.0.resource_record_type}"
  zone_id = "${data.aws_route53_zone.selected.zone_id}"
  records = ["${aws_acm_certificate.default.domain_validation_options.0.resource_record_value}"]
  ttl     = "60"
}

resource "aws_acm_certificate_validation" "default" {
  certificate_arn = "${aws_acm_certificate.default.arn}"
  validation_record_fqdns = [
    "${aws_route53_record.validation.fqdn}",
  ]
}
