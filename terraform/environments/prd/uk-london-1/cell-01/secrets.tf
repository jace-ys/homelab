resource "oci_kms_vault" "k3s" {
  compartment_id = data.oci_identity_compartment.cell.id
  display_name   = replace(local.k3s_cluster_name, ".", "-")
  vault_type     = "DEFAULT"
}

resource "oci_kms_key" "k3s" {
  compartment_id      = data.oci_identity_compartment.cell.id
  display_name        = replace(local.k3s_cluster_name, ".", "-")
  management_endpoint = oci_kms_vault.k3s.management_endpoint
  protection_mode     = "SOFTWARE"

  key_shape {
    algorithm = "AES"
    length    = 32
  }
}

resource "oci_vault_secret" "cloudflare_api_token" {
  compartment_id = data.oci_identity_compartment.cell.id
  vault_id       = oci_kms_vault.k3s.id
  key_id         = oci_kms_key.k3s.id
  secret_name    = "cloudflare_api_token"

  secret_content {
    content_type = "BASE64"
    content      = base64encode(var.cloudflare_api_token)
  }
}
