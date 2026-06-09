output "jaceystan_com_name_servers" {
  value = cloudflare_zone.jaceystan_com.name_servers
}

output "jaceystan_com_zone_id" {
  value = cloudflare_zone.jaceystan_com.id
}

output "jaceystan_com_dev_domain" {
  value = "dev.${cloudflare_zone.jaceystan_com.name}"
}

output "jaceystan_com_dev_homelab_domain" {
  value = "homelab.dev.${cloudflare_zone.jaceystan_com.name}"
}

output "jaceystan_com_stg_domain" {
  value = "stg.${cloudflare_zone.jaceystan_com.name}"
}

output "jaceystan_com_stg_homelab_domain" {
  value = "homelab.stg.${cloudflare_zone.jaceystan_com.name}"
}

output "jaceystan_com_prd_domain" {
  value = cloudflare_zone.jaceystan_com.name
}

output "jaceystan_com_prd_homelab_domain" {
  value = "homelab.${cloudflare_zone.jaceystan_com.name}"
}
