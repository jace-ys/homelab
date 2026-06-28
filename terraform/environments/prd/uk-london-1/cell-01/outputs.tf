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
    cluster = {
      name = local.k3s_cluster_name
      url  = "https://${local.k3s_cluster_fqdn}:6443"
    }
    kubeconfig = {
      bucket = oci_objectstorage_bucket.k3s_kubeconfigs.name
      objects = [
        "${local.k3s_cluster_name}_cluster-admin.yaml",
        "${local.k3s_cluster_name}_cluster-viewer.yaml",
      ]
    }
  }
}

output "argocd" {
  value = {
    url = "https://argocd.${var.base_domain_internal}"
  }
}
