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
  ]
}
