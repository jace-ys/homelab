terraform {
  required_version = "~> 1.12"

  required_providers {
    spacelift = {
      source  = "spacelift-io/spacelift"
      version = "~> 1.52"
    }
  }
}

provider "spacelift" {
}

data "spacelift_space" "root" {
  space_id = "root"
}
