data "oci_identity_compartment" "cell" {
  id = var.cell_compartment_ids[var.cell_id]
}

data "oci_identity_availability_domains" "all" {
  compartment_id = var.oci_tenancy_ocid
}

locals {
  ads = data.oci_identity_availability_domains.all.availability_domains
  fds = ["FAULT-DOMAIN-1", "FAULT-DOMAIN-2", "FAULT-DOMAIN-3"]

  vcn_cidr                = "10.0.0.0/16"
  lb_external_subnet_cidr = "10.0.0.0/24"
  lb_internal_subnet_cidr = "10.0.1.0/24"
  k3s_subnet_cidr         = "10.0.2.0/24"
}
