terraform {
  required_version = "~> 1.12"

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.21"
    }
    kustomization = {
      source  = "kbst/kustomization"
      version = "~> 0.9"
    }
    oci = {
      source  = "oracle/oci"
      version = "~> 8.20"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.9"
    }
  }
}

provider "oci" {
  tenancy_ocid     = var.oci_tenancy_ocid
  user_ocid        = var.oci_user_ocid
  fingerprint      = var.oci_fingerprint
  private_key_path = var.oci_private_key_path
  region           = var.oci_region
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

provider "kustomization" {
  kubeconfig_raw = ""
}

locals {
  secrets = try(yamldecode(file("${path.module}/data/secrets.yaml")), {})
}
