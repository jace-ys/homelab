output "cell_compartment_ids" {
  value = { for k, v in oci_identity_compartment.cell : v.name => v.id }
}
