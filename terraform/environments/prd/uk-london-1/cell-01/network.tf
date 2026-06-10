resource "oci_core_vcn" "default" {
  compartment_id = data.oci_identity_compartment.cell.id
  display_name   = "default"
  dns_label      = "default"
  cidr_blocks    = [local.vcn_cidr]
}

resource "oci_core_internet_gateway" "default" {
  compartment_id = data.oci_identity_compartment.cell.id
  vcn_id         = oci_core_vcn.default.id
  display_name   = "default"
  enabled        = true
}

resource "oci_core_nat_gateway" "default" {
  compartment_id = data.oci_identity_compartment.cell.id
  vcn_id         = oci_core_vcn.default.id
  display_name   = "default"
}

/*
LB External
*/

resource "oci_core_route_table" "lb_external" {
  compartment_id = data.oci_identity_compartment.cell.id
  vcn_id         = oci_core_vcn.default.id
  display_name   = "lb-external"

  route_rules {
    destination       = "0.0.0.0/0"
    network_entity_id = oci_core_internet_gateway.default.id
  }
}

resource "oci_core_subnet" "lb_external" {
  compartment_id             = data.oci_identity_compartment.cell.id
  vcn_id                     = oci_core_vcn.default.id
  display_name               = "lb-external"
  dns_label                  = "lbext"
  cidr_block                 = local.lb_external_subnet_cidr
  prohibit_public_ip_on_vnic = false
  route_table_id             = oci_core_route_table.lb_external.id
}

/*
LB Internal
*/

resource "oci_core_route_table" "lb_internal" {
  compartment_id = data.oci_identity_compartment.cell.id
  vcn_id         = oci_core_vcn.default.id
  display_name   = "lb-internal"

  route_rules {
    destination       = "0.0.0.0/0"
    network_entity_id = oci_core_internet_gateway.default.id
  }
}

resource "oci_core_subnet" "lb_internal" {
  compartment_id             = data.oci_identity_compartment.cell.id
  vcn_id                     = oci_core_vcn.default.id
  display_name               = "lb-internal"
  dns_label                  = "lbint"
  cidr_block                 = local.lb_internal_subnet_cidr
  prohibit_public_ip_on_vnic = false
  route_table_id             = oci_core_route_table.lb_internal.id
}

/*
K3s
*/

resource "oci_core_route_table" "k3s" {
  compartment_id = data.oci_identity_compartment.cell.id
  vcn_id         = oci_core_vcn.default.id
  display_name   = "k3s"

  route_rules {
    destination       = "0.0.0.0/0"
    network_entity_id = oci_core_nat_gateway.default.id
  }
}

resource "oci_core_subnet" "k3s" {
  compartment_id             = data.oci_identity_compartment.cell.id
  vcn_id                     = oci_core_vcn.default.id
  display_name               = "k3s"
  dns_label                  = "k3s"
  cidr_block                 = local.k3s_subnet_cidr
  prohibit_public_ip_on_vnic = true
  route_table_id             = oci_core_route_table.k3s.id
  security_list_ids          = [oci_core_vcn.default.default_security_list_id]
}
