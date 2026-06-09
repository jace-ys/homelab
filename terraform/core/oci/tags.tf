resource "oci_identity_tag_namespace" "terraform" {
  compartment_id = var.oci_tenancy_ocid
  description    = "Terraform metadata tags"
  name           = "Terraform"
}

resource "oci_identity_tag" "terraform_managed" {
  description      = "Terraform managed"
  name             = "Managed"
  tag_namespace_id = oci_identity_tag_namespace.terraform.id
  is_cost_tracking = true

  validator {
    validator_type = "ENUM"
    values         = ["true", "false"]
  }
}

resource "oci_identity_tag_default" "terraform_managed" {
  compartment_id    = var.oci_tenancy_ocid
  tag_definition_id = oci_identity_tag.terraform_managed.id
  value             = "true"
  is_required       = false
}

resource "oci_identity_tag" "terraform_repository" {
  description      = "Source repository"
  name             = "Repository"
  tag_namespace_id = oci_identity_tag_namespace.terraform.id
  is_cost_tracking = true
}

resource "oci_identity_tag_default" "terraform_repository" {
  compartment_id    = var.oci_tenancy_ocid
  tag_definition_id = oci_identity_tag.terraform_repository.id
  value             = "github.com/jace-ys/homelab"
  is_required       = false
}

resource "oci_identity_tag_namespace" "infra" {
  compartment_id = var.oci_tenancy_ocid
  description    = "Infrastructure metadata tags"
  name           = "Infra"
}

resource "oci_identity_tag" "infra_environment" {
  description      = "Environment name"
  name             = "Environment"
  tag_namespace_id = oci_identity_tag_namespace.infra.id
  is_cost_tracking = true

  validator {
    validator_type = "ENUM"
    values         = ["root"]
  }
}

resource "oci_identity_tag_default" "infra_environment" {
  compartment_id    = var.oci_tenancy_ocid
  tag_definition_id = oci_identity_tag.infra_environment.id
  value             = "root"
  is_required       = false
}

resource "oci_identity_tag" "infra_region" {
  description      = "OCI region"
  name             = "Region"
  tag_namespace_id = oci_identity_tag_namespace.infra.id
  is_cost_tracking = true
}

resource "oci_identity_tag_default" "infra_region" {
  compartment_id    = var.oci_tenancy_ocid
  tag_definition_id = oci_identity_tag.infra_region.id
  value             = var.oci_region
  is_required       = false
}

resource "oci_identity_tag" "infra_cell_name" {
  description      = "Cell name"
  name             = "CellName"
  tag_namespace_id = oci_identity_tag_namespace.infra.id
  is_cost_tracking = true
}

resource "oci_identity_tag_default" "infra_cell_name" {
  compartment_id    = var.oci_tenancy_ocid
  tag_definition_id = oci_identity_tag.infra_cell_name.id
  value             = "null"
  is_required       = false
}

resource "oci_identity_tag" "infra_cell_id" {
  description      = "Cell ID"
  name             = "CellID"
  tag_namespace_id = oci_identity_tag_namespace.infra.id
  is_cost_tracking = true
}

resource "oci_identity_tag_default" "infra_cell_id" {
  compartment_id    = var.oci_tenancy_ocid
  tag_definition_id = oci_identity_tag.infra_cell_id.id
  value             = "null"
  is_required       = false
}

resource "oci_identity_tag_namespace" "k3s" {
  compartment_id = var.oci_tenancy_ocid
  description    = "K3s metadata tags"
  name           = "K3s"
}

resource "oci_identity_tag" "k3s_node_role" {
  description      = "K3s node role"
  name             = "NodeRole"
  tag_namespace_id = oci_identity_tag_namespace.k3s.id
  is_cost_tracking = true

  validator {
    validator_type = "ENUM"
    values         = ["server", "agent"]
  }
}
