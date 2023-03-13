resource "cloudflare_access_application" "main_zone_oci_admin_ssh" {
  zone_id          = data.cloudflare_zone.main_zone.id
  name             = "SSH to the OCI instance hosting ${local.cloudflare_main_zone} (for manual accesses by Administrators)"
  domain           = "oci--ssh--admin.${local.cloudflare_main_zone}"
  type             = "self_hosted"
  session_duration = "24h"
}

resource "cloudflare_access_ca_certificate" "main_zone_oci_admin_ssh" {
  account_id     = local.cloudflare_account_id
  application_id = cloudflare_access_application.main_zone_oci_admin_ssh.id
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
    email = [local.cloudflare_user_email]
  }
}

resource "cloudflare_access_application" "main_zone_oci_machine_ssh" {
  zone_id          = data.cloudflare_zone.main_zone.id
  name             = "SSH to the OCI instance hosting ${local.cloudflare_main_zone} (for machine accesses)"
  domain           = "oci--ssh--automation.${local.cloudflare_main_zone}"
  type             = "self_hosted"
  session_duration = "24h"
}

resource "random_password" "main_zone_oci_ssh_tunnel_secret" {
  length = 64
}

resource "cloudflare_tunnel" "main_zone_oci_ssh" {
  account_id = data.cloudflare_zone.main_zone.account_id
  name       = "kory33-net-oci-ssh"
  secret     = base64encode(random_password.main_zone_oci_ssh_tunnel_secret.result)
}

resource "cloudflare_tunnel_config" "main_zone_oci_ssh" {
  account_id = data.cloudflare_zone.main_zone.account_id
  tunnel_id  = cloudflare_tunnel.main_zone_oci_ssh.id

  config {
    ingress_rule {
      hostname = "oci--ssh--admin.${local.cloudflare_main_zone}"
      service  = "ssh://localhost:22"
    }

    ingress_rule {
      hostname = "oci--ssh--automation.${local.cloudflare_main_zone}"
      service  = "ssh://localhost:22"
    }

    ingress_rule {
      service = "http_status:404"
    }
  }
}

resource "cloudflare_record" "main_zone_oci_ssh_tunnel_routes" {
  for_each = toset([
    "oci--ssh--admin.${local.cloudflare_main_zone}",
    "oci--ssh--automation.${local.cloudflare_main_zone}"
  ])

  zone_id = data.cloudflare_zone.main_zone.id
  name    = each.key
  value   = "${cloudflare_tunnel.main_zone_oci_ssh.id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
}
