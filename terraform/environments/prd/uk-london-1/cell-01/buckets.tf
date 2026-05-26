data "oci_objectstorage_namespace" "os" {
  compartment_id = data.oci_identity_compartment.cell.id
}

resource "oci_objectstorage_bucket" "k3s_kubeconfigs" {
  compartment_id = data.oci_identity_compartment.cell.id
  name           = "k3s-kubeconfigs.${var.cell_id}"
  namespace      = data.oci_objectstorage_namespace.os.namespace
  access_type    = "NoPublicAccess"
  auto_tiering   = "InfrequentAccess"
  versioning     = "Disabled"
}
