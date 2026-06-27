data "oci_core_images" "ubuntu_arm" {
  compartment_id           = var.oci_tenancy_ocid
  operating_system         = "Canonical Ubuntu"
  operating_system_version = "24.04"
  shape                    = "VM.Standard.A1.Flex"
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

resource "random_password" "k3s_token" {
  length  = 64
  special = false
}

data "kustomization_overlay" "oci_ccm" {
  resources = [
    "https://raw.githubusercontent.com/oracle/oci-cloud-controller-manager/refs/tags/v1.34.0/manifests/cloud-controller-manager/oci-cloud-controller-manager.yaml",
    "https://raw.githubusercontent.com/oracle/oci-cloud-controller-manager/refs/tags/v1.34.0/manifests/cloud-controller-manager/oci-cloud-controller-manager-rbac.yaml",
  ]

  common_labels = {
    "app.kubernetes.io/name"     = "oci-cloud-controller-manager"
    "app.kubernetes.io/instance" = "oci-cloud-controller-manager"
  }

  secret_generator {
    name      = "oci-cloud-controller-manager"
    namespace = "kube-system"
    type      = "Opaque"
    literals = [
      format("cloud-provider.yaml=%s", <<-EOF
        useInstancePrincipals: true
        compartment: ${data.oci_identity_compartment.cell.id}
        vcn: ${oci_core_vcn.default.id}

        loadBalancer:
          disabled: true
        EOF
      ),
    ]
  }

  patches {
    patch = <<-EOF
      apiVersion: apps/v1
      kind: DaemonSet
      metadata:
        name: oci-cloud-controller-manager
        namespace: kube-system
      spec:
        template:
          spec:
            priorityClassName: system-node-critical
            nodeSelector:
              node-role.kubernetes.io/control-plane: "true"
            containers:
              - name: oci-cloud-controller-manager
                resources:
                  limits:
                    memory: 64Mi
                  requests:
                    cpu: 10m
                    memory: 64Mi
      EOF
  }
}

resource "oci_core_instance_configuration" "k3s_server" {
  compartment_id = data.oci_identity_compartment.cell.id
  display_name   = "k3s-server"

  instance_details {
    instance_type = "compute"

    launch_details {
      compartment_id = data.oci_identity_compartment.cell.id
      display_name   = "k3s-server"
      shape          = "VM.Standard.A1.Flex"

      defined_tags = {
        "K3s.NodeRole" = "server"
      }

      shape_config {
        ocpus         = local.k3s_node_ocpus
        memory_in_gbs = local.k3s_node_memory
      }

      source_details {
        source_type             = "image"
        image_id                = data.oci_core_images.ubuntu_arm.images[0].id
        boot_volume_size_in_gbs = 50
      }

      create_vnic_details {
        subnet_id              = oci_core_subnet.k3s.id
        assign_public_ip       = false
        skip_source_dest_check = true
        nsg_ids = [
          oci_core_network_security_group.k3s_nodes.id,
          oci_core_network_security_group.k3s_servers.id,
        ]
      }

      metadata = {
        ssh_authorized_keys = var.compute_ssh_public_key
        user_data = base64encode(templatefile("${path.module}/templates/k3s-server.cloud-init.yaml", {
          lb_external_subnet_cidr = local.lb_external_subnet_cidr
          lb_internal_subnet_cidr = local.lb_internal_subnet_cidr
          k3s_subnet_cidr         = local.k3s_subnet_cidr
          k3s_version             = local.k3s_version
          k3s_token               = random_password.k3s_token.result
          k3s_api_lb_ip           = oci_core_public_ip.lb_internal.ip_address
          k3s_cluster_name        = local.k3s_cluster_name
          k3s_cluster_fqdn        = local.k3s_cluster_fqdn
          k3s_kubeconfigs_bucket  = oci_objectstorage_bucket.k3s_kubeconfigs.name
          k3s_mysql_endpoint = format("mysql://%s:%s@tcp(%s:%d)/k3s?tls=skip-verify",
            oci_mysql_mysql_db_system.k3s.admin_username,
            random_password.mysql_k3s_root_user.result,
            oci_mysql_mysql_db_system.k3s.endpoints[0].ip_address,
            oci_mysql_mysql_db_system.k3s.endpoints[0].port,
          )
          manifests = merge(
            {
              for f in fileset("${path.module}/templates/manifests", "*.yaml") :
              f => templatefile("${path.module}/templates/manifests/${f}", {
                oci_region           = var.oci_region
                k3s_cluster_name     = local.k3s_cluster_name
                base_domain_external = var.base_domain_external
                base_domain_internal = var.base_domain_internal
                argocd_version       = local.argocd_version
                argocd_username      = local.argocd_username
                argocd_password      = bcrypt_hash.argocd_password.id
                oci_vault_k3s_id     = oci_kms_vault.k3s.id
              })
            },
            {
              "oci-ccm.yaml" = join("---\n", [
                for name, manifest in data.kustomization_overlay.oci_ccm.manifests :
                yamlencode(jsondecode(manifest))
              ])
            },
          )
        }))
      }
    }
  }

  depends_on = [oci_identity_policy.k3s_servers]

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [defined_tags]
  }
}

resource "oci_core_instance_pool" "k3s_server" {
  compartment_id            = data.oci_identity_compartment.cell.id
  display_name              = "k3s-server"
  instance_configuration_id = oci_core_instance_configuration.k3s_server.id
  size                      = local.k3s_server_count

  load_balancers {
    load_balancer_id = oci_load_balancer_load_balancer.internal.id
    backend_set_name = oci_load_balancer_backend_set.k3s_api.name
    port             = 6443
    vnic_selection   = "PrimaryVnic"
  }

  load_balancers {
    load_balancer_id = oci_network_load_balancer_network_load_balancer.external.id
    backend_set_name = oci_network_load_balancer_backend_set.gateway_external_http.name
    port             = 31080
    vnic_selection   = "PrimaryVnic"
  }

  load_balancers {
    load_balancer_id = oci_network_load_balancer_network_load_balancer.external.id
    backend_set_name = oci_network_load_balancer_backend_set.gateway_external_https.name
    port             = 31443
    vnic_selection   = "PrimaryVnic"
  }

  load_balancers {
    load_balancer_id = oci_load_balancer_load_balancer.internal.id
    backend_set_name = oci_load_balancer_backend_set.gateway_internal_http.name
    port             = 32080
    vnic_selection   = "PrimaryVnic"
  }

  load_balancers {
    load_balancer_id = oci_load_balancer_load_balancer.internal.id
    backend_set_name = oci_load_balancer_backend_set.gateway_internal_https.name
    port             = 32443
    vnic_selection   = "PrimaryVnic"
  }

  dynamic "placement_configurations" {
    for_each = local.ads
    content {
      primary_subnet_id   = oci_core_subnet.k3s.id
      availability_domain = placement_configurations.value.name
      fault_domains       = local.fds
    }
  }
}

resource "oci_core_instance_configuration" "k3s_agent" {
  compartment_id = data.oci_identity_compartment.cell.id
  display_name   = "k3s-agent"

  instance_details {
    instance_type = "compute"

    launch_details {
      compartment_id = data.oci_identity_compartment.cell.id
      display_name   = "k3s-agent"
      shape          = "VM.Standard.A1.Flex"

      defined_tags = {
        "K3s.NodeRole" = "agent"
      }

      shape_config {
        ocpus         = local.k3s_node_ocpus
        memory_in_gbs = local.k3s_node_memory
      }

      source_details {
        source_type             = "image"
        image_id                = data.oci_core_images.ubuntu_arm.images[0].id
        boot_volume_size_in_gbs = 50
      }

      create_vnic_details {
        subnet_id              = oci_core_subnet.k3s.id
        assign_public_ip       = false
        skip_source_dest_check = true
        nsg_ids = [
          oci_core_network_security_group.k3s_nodes.id,
          oci_core_network_security_group.k3s_agents.id,
        ]
      }

      metadata = {
        ssh_authorized_keys = var.compute_ssh_public_key
        user_data = base64encode(templatefile("${path.module}/templates/k3s-agent.cloud-init.yaml", {
          lb_external_subnet_cidr = local.lb_external_subnet_cidr
          lb_internal_subnet_cidr = local.lb_internal_subnet_cidr
          k3s_subnet_cidr         = local.k3s_subnet_cidr
          k3s_version             = local.k3s_version
          k3s_token               = random_password.k3s_token.result
          k3s_api_lb_ip           = oci_core_public_ip.lb_internal.ip_address
        }))
      }
    }
  }

  depends_on = [oci_identity_policy.k3s_agents]

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [defined_tags]
  }
}

resource "oci_core_instance_pool" "k3s_agent" {
  compartment_id            = data.oci_identity_compartment.cell.id
  display_name              = "k3s-agent"
  instance_configuration_id = oci_core_instance_configuration.k3s_agent.id
  size                      = local.k3s_agent_count

  load_balancers {
    load_balancer_id = oci_network_load_balancer_network_load_balancer.external.id
    backend_set_name = oci_network_load_balancer_backend_set.gateway_external_http.name
    port             = 31080
    vnic_selection   = "PrimaryVnic"
  }

  load_balancers {
    load_balancer_id = oci_network_load_balancer_network_load_balancer.external.id
    backend_set_name = oci_network_load_balancer_backend_set.gateway_external_https.name
    port             = 31443
    vnic_selection   = "PrimaryVnic"
  }

  load_balancers {
    load_balancer_id = oci_load_balancer_load_balancer.internal.id
    backend_set_name = oci_load_balancer_backend_set.gateway_internal_http.name
    port             = 32080
    vnic_selection   = "PrimaryVnic"
  }

  load_balancers {
    load_balancer_id = oci_load_balancer_load_balancer.internal.id
    backend_set_name = oci_load_balancer_backend_set.gateway_internal_https.name
    port             = 32443
    vnic_selection   = "PrimaryVnic"
  }

  dynamic "placement_configurations" {
    for_each = local.ads
    content {
      primary_subnet_id   = oci_core_subnet.k3s.id
      availability_domain = placement_configurations.value.name
      fault_domains       = local.fds
    }
  }
}
