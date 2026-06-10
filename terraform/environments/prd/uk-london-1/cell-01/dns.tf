resource "cloudflare_dns_record" "external" {
  zone_id = var.cloudflare_zone_id
  name    = "*.${var.base_domain_external}"
  type    = "A"
  content = oci_core_public_ip.lb_external.ip_address
  proxied = false
  ttl     = 3600
}

resource "cloudflare_dns_record" "internal" {
  zone_id = var.cloudflare_zone_id
  name    = "*.${var.base_domain_internal}"
  type    = "A"
  content = oci_core_public_ip.lb_internal.ip_address
  proxied = false
  ttl     = 3600
}
