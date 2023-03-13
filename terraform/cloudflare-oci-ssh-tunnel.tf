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
      hostname = cloudflare_access_application.main_zone_oci_admin_ssh.domain
      service  = "ssh://localhost:22"
    }

    ingress_rule {
      hostname = cloudflare_access_application.main_zone_oci_machine_ssh.domain
      service  = "ssh://localhost:22"
    }

    ingress_rule {
      service = "http_status:404"
    }
  }
}

resource "cloudflare_record" "main_zone_oci_ssh_tunnel_routes" {
  for_each = toset([
    cloudflare_access_application.main_zone_oci_admin_ssh.domain,
    cloudflare_access_application.main_zone_oci_machine_ssh.domain,
  ])

  zone_id = data.cloudflare_zone.main_zone.id
  name    = each.key
  value   = "${cloudflare_tunnel.main_zone_oci_ssh.id}.cfargotunnel.com"
  type    = "CNAME"
  proxied = true
}
