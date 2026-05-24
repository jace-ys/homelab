output "jaceystan_com_name_servers" {
  value = cloudflare_zone.jaceystan_com.name_servers
}

output "jaceystan_com_zone_id" {
  value = cloudflare_zone.jaceystan_com.id
}

output "dev_jaceystan_com" {
  value = "dev.${cloudflare_zone.jaceystan_com.name}"
}

output "homelab_dev_jaceystan_com" {
  value = "homelab.dev.${cloudflare_zone.jaceystan_com.name}"
}

output "stg_jaceystan_com" {
  value = "stg.${cloudflare_zone.jaceystan_com.name}"
}

output "homelab_stg_jaceystan_com" {
  value = "homelab.stg.${cloudflare_zone.jaceystan_com.name}"
}

output "prd_jaceystan_com" {
  value = cloudflare_zone.jaceystan_com.name
}

output "homelab_prd_jaceystan_com" {
  value = "homelab.${cloudflare_zone.jaceystan_com.name}"
}
