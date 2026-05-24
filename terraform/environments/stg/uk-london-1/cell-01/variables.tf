variable "oci_tenancy_ocid" {}
variable "oci_user_ocid" {}
variable "oci_fingerprint" {}
variable "oci_private_key_path" {}
variable "oci_region" {}

variable "cloudflare_account_id" {}
variable "cloudflare_api_token" {
  sensitive = true
}
variable "cloudflare_zone_id" {}

variable "domain_name_external" {}
variable "domain_name_internal" {}

variable "cell_compartment_ids" {
  type = map(string)
}
variable "cell_environment" {}
variable "cell_name" {}
variable "cell_id" {}

variable "ssh_public_key" {}
