resource "cloudflare_access_application" "main_zone_oci_admin_ssh" {
  zone_id          = data.cloudflare_zone.main_zone.id
  name             = "SSH to the OCI instance hosting ${local.cloudflare_main_zone} (for manual accesses by Administrators)"
  domain           = "oci--ssh--admin.${local.cloudflare_main_zone}"
  type             = "self_hosted"
  session_duration = "24h"
}

resource "cloudflare_access_policy" "main_zone_oci_admin_ssh" {
  application_id = cloudflare_access_application.main_zone_oci_admin_ssh.id
  zone_id        = cloudflare_access_application.main_zone_oci_admin_ssh.zone_id
  name           = "Allow Administrators to SSH"
  precedence     = "1"
  decision       = "allow"

  include {
    everyone = true
  }

  require {
    # Only allow the administrator to access
    email = [local.cloudflare_user_email]
  }
}

resource "cloudflare_access_ca_certificate" "main_zone_oci_admin_ssh" {
  # We will issue short-lived certificates to admin accesses
  depends_on     = [cloudflare_access_policy.main_zone_oci_admin_ssh]
  account_id     = local.cloudflare_account_id
  application_id = cloudflare_access_application.main_zone_oci_admin_ssh.id
}
