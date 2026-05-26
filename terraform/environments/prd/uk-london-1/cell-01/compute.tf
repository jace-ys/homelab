data "oci_core_images" "ubuntu_arm" {
  compartment_id           = var.oci_tenancy_ocid
  operating_system         = "Canonical Ubuntu"
  operating_system_version = "24.04"
  shape                    = "VM.Standard.A1.Flex"
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

data "oci_identity_availability_domains" "all" {
  compartment_id = var.oci_tenancy_ocid
}

locals {
  k3s_version = "v1.35.5+k3s1"

  k3s_server_count = 1
  k3s_agent_count  = 3

  k3s_node_ocpus  = 1
  k3s_node_memory = 6

  k3s_kubeconfig_object = "${local.k3s_cluster_name}-cluster-viewer.yaml"

  ads = data.oci_identity_availability_domains.all.availability_domains
  fds = ["FAULT-DOMAIN-1", "FAULT-DOMAIN-2", "FAULT-DOMAIN-3"]
}

resource "random_password" "k3s_token" {
  length  = 64
  special = false
}

resource "oci_core_instance" "k3s_server" {
  count = local.k3s_server_count

  compartment_id      = data.oci_identity_compartment.cell.id
  display_name        = "k3s-server-${count.index}"
  availability_domain = local.ads[count.index % length(local.ads)].name
  fault_domain        = local.fds[count.index % length(local.fds)]
  shape               = "VM.Standard.A1.Flex"

  defined_tags = {
    "K3s.NodeRole" = "server"
  }

  shape_config {
    ocpus         = local.k3s_node_ocpus
    memory_in_gbs = local.k3s_node_memory
  }

  source_details {
    source_type             = "image"
    source_id               = data.oci_core_images.ubuntu_arm.images[0].id
    boot_volume_size_in_gbs = 50
  }

  create_vnic_details {
    subnet_id              = oci_core_subnet.k3s.id
    hostname_label         = "k3s-server-${count.index}"
    private_ip             = cidrhost(local.k3s_subnet_cidr, count.index + 10)
    assign_public_ip       = false
    skip_source_dest_check = true
    nsg_ids = [
      oci_core_network_security_group.k3s_nodes.id,
      oci_core_network_security_group.k3s_servers.id,
    ]
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
    user_data = base64encode(templatefile("${path.module}/templates/k3s-server.cloud-init.yaml", {
      manifests = {
        for f in fileset("${path.module}/templates/manifests", "*.yaml") :
        f => file("${path.module}/templates/manifests/${f}")
      }
      lb_external_subnet_cidr = local.lb_external_subnet_cidr
      lb_internal_subnet_cidr = local.lb_internal_subnet_cidr
      k3s_subnet_cidr         = local.k3s_subnet_cidr
      k3s_version             = local.k3s_version
      k3s_token               = random_password.k3s_token.result
      k3s_api_fqdn            = local.k3s_cluster_name
      k3s_api_lb_ip           = oci_core_public_ip.lb_internal.ip_address
      k3s_kubeconfigs_bucket  = oci_objectstorage_bucket.k3s_kubeconfigs.name
      k3s_kubeconfig_object   = local.k3s_kubeconfig_object
      k3s_mysql_endpoint = format("mysql://%s:%s@tcp(%s:%d)/k3s?tls=skip-verify",
        oci_mysql_mysql_db_system.k3s.admin_username,
        random_password.mysql_k3s_root_user.result,
        oci_mysql_mysql_db_system.k3s.endpoints[0].ip_address,
        oci_mysql_mysql_db_system.k3s.endpoints[0].port,
      )
    }))
  }

  depends_on = [oci_identity_policy.k3s_servers]

  lifecycle {
    ignore_changes = [defined_tags]
  }
}

resource "oci_core_instance" "k3s_agent" {
  count = local.k3s_agent_count

  compartment_id      = data.oci_identity_compartment.cell.id
  display_name        = "k3s-agent-${count.index}"
  availability_domain = local.ads[count.index % length(local.ads)].name
  fault_domain        = local.fds[count.index % length(local.fds)]
  shape               = "VM.Standard.A1.Flex"

  defined_tags = {
    "K3s.NodeRole" = "agent"
  }

  shape_config {
    ocpus         = local.k3s_node_ocpus
    memory_in_gbs = local.k3s_node_memory
  }

  source_details {
    source_type             = "image"
    source_id               = data.oci_core_images.ubuntu_arm.images[0].id
    boot_volume_size_in_gbs = 50
  }

  create_vnic_details {
    subnet_id              = oci_core_subnet.k3s.id
    hostname_label         = "k3s-agent-${count.index}"
    assign_public_ip       = false
    skip_source_dest_check = true
    nsg_ids = [
      oci_core_network_security_group.k3s_nodes.id,
      oci_core_network_security_group.k3s_agents.id,
    ]
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
    user_data = base64encode(templatefile("${path.module}/templates/k3s-agent.cloud-init.yaml", {
      lb_external_subnet_cidr = local.lb_external_subnet_cidr
      lb_internal_subnet_cidr = local.lb_internal_subnet_cidr
      k3s_subnet_cidr         = local.k3s_subnet_cidr
      k3s_version             = local.k3s_version
      k3s_token               = random_password.k3s_token.result
      k3s_api_lb_ip           = oci_core_public_ip.lb_internal.ip_address
    }))
  }

  lifecycle {
    ignore_changes = [defined_tags]
  }
}
