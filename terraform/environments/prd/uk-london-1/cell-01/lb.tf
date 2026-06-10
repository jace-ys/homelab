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

# Traefik HTTP

resource "oci_load_balancer_backend_set" "traefik_http" {
  load_balancer_id = oci_load_balancer_load_balancer.internal.id
  name             = "traefik-http"
  policy           = "ROUND_ROBIN"

  health_checker {
    protocol = "TCP"
    port     = 30080
  }
}

resource "oci_load_balancer_listener" "traefik_http" {
  load_balancer_id         = oci_load_balancer_load_balancer.internal.id
  name                     = "traefik-http"
  default_backend_set_name = oci_load_balancer_backend_set.traefik_http.name
  port                     = 80
  protocol                 = "TCP"
}

# Traefik HTTPS

resource "oci_load_balancer_backend_set" "traefik_https" {
  load_balancer_id = oci_load_balancer_load_balancer.internal.id
  name             = "traefik-https"
  policy           = "ROUND_ROBIN"

  health_checker {
    protocol = "TCP"
    port     = 30443
  }
}

resource "oci_load_balancer_listener" "traefik_https" {
  load_balancer_id         = oci_load_balancer_load_balancer.internal.id
  name                     = "traefik-https"
  default_backend_set_name = oci_load_balancer_backend_set.traefik_https.name
  port                     = 443
  protocol                 = "TCP"
}

# K3s API

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
