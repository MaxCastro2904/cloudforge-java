resource "aws_cloudfront_distribution" "https" {
  enabled             = true
  comment             = "CloudForge Java HTTPS"
  is_ipv6_enabled     = true
  http_version        = "http2"
  price_class         = "PriceClass_100"
  wait_for_deployment = true
  retain_on_delete    = false

  origin {
    domain_name = aws_lb.main.dns_name
    origin_id   = "cloudforge-alb"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    target_origin_id       = "cloudforge-alb"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true
    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 0

    forwarded_values {
      query_string = true

      cookies {
        forward = "none"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

# Adopta la distribución existente sin crear otra.
# Eliminar este bloque después de la primera aplicación exitosa.
import {
  to = aws_cloudfront_distribution.https
  id = "E3J8UZJT85GO3C"
}

output "https_url" {
  value = "https://${aws_cloudfront_distribution.https.domain_name}"
}

output "https_hello_url" {
  value = "https://${aws_cloudfront_distribution.https.domain_name}/api/hello"
}
