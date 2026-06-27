resource "oci_identity_dynamic_group" "k3s_servers" {
  compartment_id = var.oci_tenancy_ocid
  name           = "k3s-servers"
  description    = "Dynamic group identity for K3s server instances"

  matching_rule = "ALL {instance.compartment.id = '${data.oci_identity_compartment.cell.id}', tag.K3s.NodeRole.value = 'server'}"
}

resource "oci_identity_policy" "k3s_servers" {
  compartment_id = data.oci_identity_compartment.cell.id
  name           = "k3s-servers"
  description    = "IAM policy for K3s server instances"

  statements = [
    format("Allow dynamic-group %s to manage objects in compartment id %s where target.bucket.name = '%s'",
      oci_identity_dynamic_group.k3s_servers.name,
      data.oci_identity_compartment.cell.id,
      oci_objectstorage_bucket.k3s_kubeconfigs.name,
    ),
    format("Allow dynamic-group %s to read instance-family in compartment id %s",
      oci_identity_dynamic_group.k3s_servers.name,
      data.oci_identity_compartment.cell.id,
    ),
    format("Allow dynamic-group %s to use virtual-network-family in compartment id %s",
      oci_identity_dynamic_group.k3s_servers.name,
      data.oci_identity_compartment.cell.id,
    ),
    format("Allow dynamic-group %s to read secret-bundles in compartment id %s",
      oci_identity_dynamic_group.k3s_servers.name,
      data.oci_identity_compartment.cell.id,
    ),
    format("Allow dynamic-group %s to use vaults in compartment id %s",
      oci_identity_dynamic_group.k3s_servers.name,
      data.oci_identity_compartment.cell.id,
    ),
    format("Allow dynamic-group %s to use keys in compartment id %s",
      oci_identity_dynamic_group.k3s_servers.name,
      data.oci_identity_compartment.cell.id,
    ),
  ]
}

resource "oci_identity_dynamic_group" "k3s_agents" {
  compartment_id = var.oci_tenancy_ocid
  name           = "k3s-agents"
  description    = "Dynamic group identity for K3s agent instances"

  matching_rule = "ALL {instance.compartment.id = '${data.oci_identity_compartment.cell.id}', tag.K3s.NodeRole.value = 'agent'}"
}

resource "oci_identity_policy" "k3s_agents" {
  compartment_id = data.oci_identity_compartment.cell.id
  name           = "k3s-agents"
  description    = "IAM policy for K3s agent instances"

  statements = [
    format("Allow dynamic-group %s to read instance-family in compartment id %s",
      oci_identity_dynamic_group.k3s_agents.name,
      data.oci_identity_compartment.cell.id,
    ),
    format("Allow dynamic-group %s to use virtual-network-family in compartment id %s",
      oci_identity_dynamic_group.k3s_agents.name,
      data.oci_identity_compartment.cell.id,
    ),
    format("Allow dynamic-group %s to read secret-bundles in compartment id %s",
      oci_identity_dynamic_group.k3s_agents.name,
      data.oci_identity_compartment.cell.id,
    ),
    format("Allow dynamic-group %s to use vaults in compartment id %s",
      oci_identity_dynamic_group.k3s_agents.name,
      data.oci_identity_compartment.cell.id,
    ),
    format("Allow dynamic-group %s to use keys in compartment id %s",
      oci_identity_dynamic_group.k3s_agents.name,
      data.oci_identity_compartment.cell.id,
    ),
  ]
}

resource "oci_identity_policy" "mysqldbsystem" {
  compartment_id = var.oci_tenancy_ocid
  name           = "mysqldbsystem"
  description    = "IAM policy for MySQL DB system provisioning"

  statements = [
    format(
      "Allow any-user to {NETWORK_SECURITY_GROUP_UPDATE_MEMBERS} in compartment id %s where all {request.principal.type='mysqldbsystem', request.resource.compartment.id='%s'}",
      data.oci_identity_compartment.cell.id,
      data.oci_identity_compartment.cell.id,
    ),
    format(
      "Allow any-user to {VNIC_CREATE, VNIC_UPDATE, VNIC_ASSOCIATE_NETWORK_SECURITY_GROUP, VNIC_DISASSOCIATE_NETWORK_SECURITY_GROUP} in compartment id %s where all {request.principal.type='mysqldbsystem', request.resource.compartment.id='%s'}",
      data.oci_identity_compartment.cell.id,
      data.oci_identity_compartment.cell.id,
    ),
  ]
}
