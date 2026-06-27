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

# Gateway External HTTP

resource "oci_network_load_balancer_listener" "gateway_external_http" {
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.external.id
  name                     = "gateway-external-http"
  default_backend_set_name = oci_network_load_balancer_backend_set.gateway_external_http.name
  port                     = 80
  protocol                 = "TCP"
}

resource "oci_network_load_balancer_backend_set" "gateway_external_http" {
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.external.id
  name                     = "gateway-external-http"
  policy                   = "ROUND_ROBIN"

  health_checker {
    protocol = "TCP"
    port     = 31080
  }
}

# Gateway External HTTPS

resource "oci_network_load_balancer_listener" "gateway_external_https" {
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.external.id
  name                     = "gateway-external-https"
  default_backend_set_name = oci_network_load_balancer_backend_set.gateway_external_https.name
  port                     = 443
  protocol                 = "TCP"
}

resource "oci_network_load_balancer_backend_set" "gateway_external_https" {
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.external.id
  name                     = "gateway-external-https"
  policy                   = "ROUND_ROBIN"

  health_checker {
    protocol = "TCP"
    port     = 31443
  }
}

# Gateway Internal HTTP

resource "oci_load_balancer_listener" "gateway_internal_http" {
  load_balancer_id         = oci_load_balancer_load_balancer.internal.id
  name                     = "gateway-internal-http"
  default_backend_set_name = oci_load_balancer_backend_set.gateway_internal_http.name
  port                     = 80
  protocol                 = "TCP"
}

resource "oci_load_balancer_backend_set" "gateway_internal_http" {
  load_balancer_id = oci_load_balancer_load_balancer.internal.id
  name             = "gateway-internal-http"
  policy           = "ROUND_ROBIN"

  health_checker {
    protocol = "TCP"
    port     = 32080
  }
}

# Gateway Internal HTTPS

resource "oci_load_balancer_listener" "gateway_internal_https" {
  load_balancer_id         = oci_load_balancer_load_balancer.internal.id
  name                     = "gateway-internal-https"
  default_backend_set_name = oci_load_balancer_backend_set.gateway_internal_https.name
  port                     = 443
  protocol                 = "TCP"
}

resource "oci_load_balancer_backend_set" "gateway_internal_https" {
  load_balancer_id = oci_load_balancer_load_balancer.internal.id
  name             = "gateway-internal-https"
  policy           = "ROUND_ROBIN"

  health_checker {
    protocol = "TCP"
    port     = 32443
  }
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
