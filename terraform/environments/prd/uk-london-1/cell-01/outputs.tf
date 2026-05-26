output "cell" {
  value = {
    environment = var.cell_environment
    region      = var.oci_region
    name        = var.cell_name
    id          = var.cell_id
  }
}

output "compartment" {
  value = {
    id   = data.oci_identity_compartment.cell.id
    name = data.oci_identity_compartment.cell.name
  }
}

output "k3s" {
  value = {
    cluster_name = local.k3s_cluster_name
    api_url      = "https://${local.k3s_cluster_name}:6443"
    kubeconfig = {
      bucket = oci_objectstorage_bucket.k3s_kubeconfigs.name
      object = local.k3s_kubeconfig_object
    }
  }
}
