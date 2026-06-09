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
