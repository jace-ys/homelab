locals {
  dirs = [
    for f in fileset("${path.module}/../../environments", "*/*/*/cell.json") : dirname(f)
  ]

  cells = {
    for dir in local.dirs : dir => {
      environment = split("/", dir)[0]
      region      = split("/", dir)[1]
      name        = split("/", dir)[2]
      id          = "${split("/", dir)[2]}.${split("/", dir)[1]}.${split("/", dir)[0]}"
    }
  }
}

resource "oci_identity_compartment" "cell" {
  for_each = local.cells

  compartment_id = var.oci_tenancy_ocid
  name           = each.value.id
  description    = "Cell [${each.value.id}]"
}

resource "oci_identity_tag_default" "cell_infra_environment" {
  for_each = local.cells

  compartment_id    = oci_identity_compartment.cell[each.key].id
  tag_definition_id = oci_identity_tag.infra_environment.id
  value             = each.value.environment
  is_required       = false
}

resource "oci_identity_tag_default" "cell_infra_region" {
  for_each = local.cells

  compartment_id    = oci_identity_compartment.cell[each.key].id
  tag_definition_id = oci_identity_tag.infra_region.id
  value             = each.value.region
  is_required       = false
}

resource "oci_identity_tag_default" "cell_infra_cell_name" {
  for_each = local.cells

  compartment_id    = oci_identity_compartment.cell[each.key].id
  tag_definition_id = oci_identity_tag.infra_cell_name.id
  value             = each.value.name
  is_required       = false
}

resource "oci_identity_tag_default" "cell_infra_cell_id" {
  for_each = local.cells

  compartment_id    = oci_identity_compartment.cell[each.key].id
  tag_definition_id = oci_identity_tag.infra_cell_id.id
  value             = each.value.id
  is_required       = false
}
