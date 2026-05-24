resource "cloudflare_zone" "jaceystan_com" {
  name = "jaceystan.com"
  account = {
    id = var.cloudflare_account_id
  }
  type = "full"
}

resource "cloudflare_zone_setting" "ssl" {
  zone_id    = cloudflare_zone.jaceystan_com.id
  setting_id = "ssl"
  value      = "strict"
}

resource "cloudflare_zone_setting" "min_tls_version" {
  zone_id    = cloudflare_zone.jaceystan_com.id
  setting_id = "min_tls_version"
  value      = "1.2"
}

resource "cloudflare_zone_setting" "always_use_https" {
  zone_id    = cloudflare_zone.jaceystan_com.id
  setting_id = "always_use_https"
  value      = "on"
}

resource "cloudflare_zone_setting" "automatic_https_rewrites" {
  zone_id    = cloudflare_zone.jaceystan_com.id
  setting_id = "automatic_https_rewrites"
  value      = "on"
}

resource "cloudflare_dns_record" "root" {
  zone_id = cloudflare_zone.jaceystan_com.id
  name    = "@"
  type    = "CNAME"
  content = "jaceys.netlify.app"
  proxied = true
  ttl     = 1
}

resource "cloudflare_dns_record" "www" {
  zone_id = cloudflare_zone.jaceystan_com.id
  name    = "www"
  type    = "CNAME"
  content = "jaceys.netlify.app"
  proxied = true
  ttl     = 1
}

resource "cloudflare_dns_record" "hello" {
  zone_id = cloudflare_zone.jaceystan_com.id
  name    = "hello"
  type    = "CNAME"
  content = "hello-jaceys.netlify.app"
  proxied = true
  ttl     = 1
}
