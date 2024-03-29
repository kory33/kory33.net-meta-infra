resource "oci_core_vcn" "main" {
  compartment_id = local.terraform_managed_compartment.id
  cidr_blocks    = ["10.0.0.0/24"]
}

resource "oci_core_subnet" "private_subnet" {
  compartment_id             = local.terraform_managed_compartment.id
  cidr_block                 = "10.0.0.0/28"
  vcn_id                     = oci_core_vcn.main.id
  prohibit_public_ip_on_vnic = true
}

data "oci_core_images" "canonical_ubuntu_22_04_on_A1_Flex" {
  compartment_id = local.terraform_managed_compartment.id

  # See https://docs.oracle.com/en-us/iaas/images/ubuntu-2204/ for available versions
  display_name = "Canonical-Ubuntu-22.04-Minimal-aarch64-2023.02.14-0"
  shape        = "VM.Standard.A1.Flex"

  lifecycle {
    postcondition {
      condition     = length(self.images) == 1
      error_message = "More than one images found: ${jsonencode(self.images)}"
    }
  }
}

resource "oci_core_instance" "main_instance" {
  compartment_id = local.terraform_managed_compartment.id
  display_name   = "kory33-net-main-instance"

  availability_domain = local.first_availability_domain.name
  shape               = "VM.Standard.A1.Flex"

  shape_config {
    ocpus         = 4
    memory_in_gbs = 24
  }

  create_vnic_details {
    assign_public_ip = false
    subnet_id        = oci_core_subnet.private_subnet.id
  }

  instance_options {
    are_legacy_imds_endpoints_disabled = true
  }

  source_details {
    boot_volume_size_in_gbs = 150

    source_type = "image"
    source_id   = data.oci_core_images.canonical_ubuntu_22_04_on_A1_Flex.images[0].id
  }
}
