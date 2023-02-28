data "cloudflare_zone" "main_zone" {
  account_id = local.cloudflare_account_id
  name       = local.cloudflare_main_zone
}
