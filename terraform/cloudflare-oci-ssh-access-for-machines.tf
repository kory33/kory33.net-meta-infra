resource "cloudflare_access_application" "main_zone_oci_machine_ssh" {
  zone_id          = data.cloudflare_zone.main_zone.id
  name             = "SSH to the OCI instance hosting ${local.cloudflare_main_zone} (for machine accesses)"
  domain           = "oci--ssh--automation.${local.cloudflare_main_zone}"
  type             = "self_hosted"
  session_duration = "24h"
}

# We leave the machine access application itself unprotected.
#
# Any machine-client that wishes to SSH into the OCI instance shall
# first POST /new-short-lived-certificate to the cf-worker-as-openssh-ca domain
# with a suitable bearer token to obtain a short-lived certificate.
