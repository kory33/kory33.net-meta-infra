data "cloudflare_zone" "main_zone" {
  account_id = local.account_id
  name       = local.main_zone
}
