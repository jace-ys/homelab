data "oci_identity_compartment" "cell" {
  id = var.cell_compartment_ids[var.cell_id]
}

locals {
  k3s_cluster_name = "k3s.${var.domain_name_internal}"

  vcn_cidr                = "10.0.0.0/16"
  lb_external_subnet_cidr = "10.0.0.0/24"
  lb_internal_subnet_cidr = "10.0.1.0/24"
  k3s_subnet_cidr         = "10.0.2.0/24"
}
