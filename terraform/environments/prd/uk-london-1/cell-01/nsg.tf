resource "oci_core_network_security_group" "lb_external" {
  compartment_id = data.oci_identity_compartment.cell.id
  vcn_id         = oci_core_vcn.default.id
  display_name   = "lb-external"
}

resource "oci_core_network_security_group" "lb_internal" {
  compartment_id = data.oci_identity_compartment.cell.id
  vcn_id         = oci_core_vcn.default.id
  display_name   = "lb-internal"
}

resource "oci_core_network_security_group" "k3s_nodes" {
  compartment_id = data.oci_identity_compartment.cell.id
  vcn_id         = oci_core_vcn.default.id
  display_name   = "k3s-nodes"
}

resource "oci_core_network_security_group" "k3s_servers" {
  compartment_id = data.oci_identity_compartment.cell.id
  vcn_id         = oci_core_vcn.default.id
  display_name   = "k3s-servers"
}

resource "oci_core_network_security_group" "k3s_agents" {
  compartment_id = data.oci_identity_compartment.cell.id
  vcn_id         = oci_core_vcn.default.id
  display_name   = "k3s-agents"
}

resource "oci_core_network_security_group" "mysql_k3s" {
  compartment_id = data.oci_identity_compartment.cell.id
  vcn_id         = oci_core_vcn.default.id
  display_name   = "mysql-k3s"
}

/*
LB Internal
*/

resource "oci_core_network_security_group_security_rule" "lb_internal_ingress" {
  for_each = {
    k3s_api = {
      protocol    = "6"
      source_type = "CIDR_BLOCK"
      source      = "0.0.0.0/0"
      port_min    = 6443
      port_max    = 6443
    }
  }

  network_security_group_id = oci_core_network_security_group.lb_internal.id
  direction                 = "INGRESS"
  protocol                  = each.value.protocol
  source_type               = each.value.source_type
  source                    = each.value.source

  dynamic "tcp_options" {
    for_each = each.value.protocol == "6" ? [1] : []
    content {
      destination_port_range {
        min = each.value.port_min
        max = each.value.port_max
      }
    }
  }
}

resource "oci_core_network_security_group_security_rule" "lb_internal_egress" {
  for_each = {
    k3s_api = {
      protocol         = "6"
      destination_type = "NETWORK_SECURITY_GROUP"
      destination      = oci_core_network_security_group.k3s_servers.id
      port_min         = 6443
      port_max         = 6443
    }
  }

  network_security_group_id = oci_core_network_security_group.lb_internal.id
  direction                 = "EGRESS"
  protocol                  = each.value.protocol
  destination_type          = each.value.destination_type
  destination               = each.value.destination

  dynamic "tcp_options" {
    for_each = each.value.protocol == "6" ? [1] : []
    content {
      destination_port_range {
        min = each.value.port_min
        max = each.value.port_max
      }
    }
  }
}

/*
K3s Nodes
*/

resource "oci_core_network_security_group_security_rule" "k3s_nodes_ingress" {
  for_each = {
    k3s_nodes = {
      protocol    = "all"
      source_type = "NETWORK_SECURITY_GROUP"
      source      = oci_core_network_security_group.k3s_nodes.id
    }
  }

  network_security_group_id = oci_core_network_security_group.k3s_nodes.id
  direction                 = "INGRESS"
  protocol                  = each.value.protocol
  source_type               = each.value.source_type
  source                    = each.value.source
}

resource "oci_core_network_security_group_security_rule" "k3s_nodes_egress" {
  for_each = {
    k3s_nodes = {
      protocol         = "all"
      destination_type = "NETWORK_SECURITY_GROUP"
      destination      = oci_core_network_security_group.k3s_nodes.id
    }
  }

  network_security_group_id = oci_core_network_security_group.k3s_nodes.id
  direction                 = "EGRESS"
  protocol                  = each.value.protocol
  destination_type          = each.value.destination_type
  destination               = each.value.destination
}

/*
K3s Servers
*/

resource "oci_core_network_security_group_security_rule" "k3s_servers_ingress" {
  for_each = {
    lb_internal = {
      protocol    = "6"
      source_type = "NETWORK_SECURITY_GROUP"
      source      = oci_core_network_security_group.lb_internal.id
      port_min    = 6443
      port_max    = 6443
    }
  }

  network_security_group_id = oci_core_network_security_group.k3s_servers.id
  direction                 = "INGRESS"
  protocol                  = each.value.protocol
  source_type               = each.value.source_type
  source                    = each.value.source

  dynamic "tcp_options" {
    for_each = each.value.protocol == "6" ? [1] : []
    content {
      destination_port_range {
        min = each.value.port_min
        max = each.value.port_max
      }
    }
  }
}

resource "oci_core_network_security_group_security_rule" "k3s_servers_egress" {
  for_each = {
    mysql_k3s = {
      protocol         = "6"
      destination_type = "NETWORK_SECURITY_GROUP"
      destination      = oci_core_network_security_group.mysql_k3s.id
      port_min         = oci_mysql_mysql_db_system.k3s.endpoints[0].port
      port_max         = oci_mysql_mysql_db_system.k3s.endpoints[0].port
    }
  }

  network_security_group_id = oci_core_network_security_group.k3s_servers.id
  direction                 = "EGRESS"
  protocol                  = each.value.protocol
  destination_type          = each.value.destination_type
  destination               = each.value.destination

  dynamic "tcp_options" {
    for_each = each.value.protocol == "6" ? [1] : []
    content {
      destination_port_range {
        min = each.value.port_min
        max = each.value.port_max
      }
    }
  }
}

/*
MySQL K3s
*/

resource "oci_core_network_security_group_security_rule" "mysql_k3s_ingress" {
  for_each = {
    k3s_servers = {
      protocol    = "6"
      source_type = "NETWORK_SECURITY_GROUP"
      source      = oci_core_network_security_group.k3s_servers.id
      port_min    = oci_mysql_mysql_db_system.k3s.endpoints[0].port
      port_max    = oci_mysql_mysql_db_system.k3s.endpoints[0].port
    }
  }

  network_security_group_id = oci_core_network_security_group.mysql_k3s.id
  direction                 = "INGRESS"
  protocol                  = each.value.protocol
  source_type               = each.value.source_type
  source                    = each.value.source

  dynamic "tcp_options" {
    for_each = each.value.protocol == "6" ? [1] : []
    content {
      destination_port_range {
        min = each.value.port_min
        max = each.value.port_max
      }
    }
  }
}
