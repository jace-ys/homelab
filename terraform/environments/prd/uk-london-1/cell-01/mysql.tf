resource "random_password" "mysql_k3s_root_user" {
  length           = 32
  override_special = "#!~%^*_-+=?{}()<>|.,;"
}

resource "oci_mysql_mysql_db_system" "k3s" {
  compartment_id          = data.oci_identity_compartment.cell.id
  display_name            = "k3s"
  is_highly_available     = false
  subnet_id               = oci_core_subnet.k3s.id
  nsg_ids                 = [oci_core_network_security_group.mysql_k3s.id]
  availability_domain     = local.ads[2].name
  shape_name              = "MySQL.Free"
  data_storage_size_in_gb = 50
  admin_username          = "root"
  admin_password          = random_password.mysql_k3s_root_user.result

  deletion_policy {
    automatic_backup_retention = "DELETE"
    is_delete_protected        = true
  }
}

resource "oci_mysql_heat_wave_cluster" "k3s" {
  db_system_id = oci_mysql_mysql_db_system.k3s.id
  shape_name   = "HeatWave.Free"
  cluster_size = 1
}
