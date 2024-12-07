# modules/route53/main.tf

# module "route53" {
#   source  = "./modules/route53"
#   alb_dns = module.ingress.alb_dns
#   domain  = var.domain
# }

# module "acm" {
#   source  = "./modules/acm"
#   domain  = var.domain
# }


# modules/route53/main.tf
resource "aws_route53_zone" "main" {
  name = var.domain
}

resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.main.zone_id
  name    = var.domain
  type    = "A"

  alias {
    name                   = var.alb_dns
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}
