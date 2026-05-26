/*
LB External
*/

resource "oci_core_public_ip" "lb_external" {
  compartment_id = data.oci_identity_compartment.cell.id
  display_name   = "lb-external"
  lifetime       = "RESERVED"

  lifecycle {
    ignore_changes = [private_ip_id]
  }
}

resource "oci_network_load_balancer_network_load_balancer" "external" {
  compartment_id             = data.oci_identity_compartment.cell.id
  display_name               = "external"
  subnet_id                  = oci_core_subnet.lb_external.id
  is_private                 = false
  network_security_group_ids = [oci_core_network_security_group.lb_external.id]

  reserved_ips {
    id = oci_core_public_ip.lb_external.id
  }
}

/*
LB Internal
*/

resource "oci_core_public_ip" "lb_internal" {
  compartment_id = data.oci_identity_compartment.cell.id
  display_name   = "lb-internal"
  lifetime       = "RESERVED"

  lifecycle {
    ignore_changes = [private_ip_id]
  }
}

resource "oci_load_balancer_load_balancer" "internal" {
  compartment_id             = data.oci_identity_compartment.cell.id
  display_name               = "internal"
  shape                      = "flexible"
  subnet_ids                 = [oci_core_subnet.lb_internal.id]
  is_private                 = false
  network_security_group_ids = [oci_core_network_security_group.lb_internal.id]

  reserved_ips {
    id = oci_core_public_ip.lb_internal.id
  }

  shape_details {
    minimum_bandwidth_in_mbps = 10
    maximum_bandwidth_in_mbps = 10
  }
}

resource "oci_load_balancer_backend_set" "k3s_api" {
  load_balancer_id = oci_load_balancer_load_balancer.internal.id
  name             = "k3s-api"
  policy           = "ROUND_ROBIN"

  health_checker {
    protocol = "TCP"
    port     = 6443
  }
}

resource "oci_load_balancer_listener" "k3s_api" {
  load_balancer_id         = oci_load_balancer_load_balancer.internal.id
  name                     = "k3s-api"
  default_backend_set_name = oci_load_balancer_backend_set.k3s_api.name
  port                     = 6443
  protocol                 = "TCP"
}

resource "oci_load_balancer_backend" "k3s_api" {
  count = local.k3s_server_count

  load_balancer_id = oci_load_balancer_load_balancer.internal.id
  backendset_name  = oci_load_balancer_backend_set.k3s_api.name
  ip_address       = cidrhost(local.k3s_subnet_cidr, count.index + 10)
  port             = 6443
}
