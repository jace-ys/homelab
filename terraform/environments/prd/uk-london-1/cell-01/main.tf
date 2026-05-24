data "oci_identity_compartment" "cell" {
  id = var.cell_compartment_ids[var.cell_id]
}

