data "cloudflare_zone" "main_zone" {
  account_id = local.account_id
  zone       = local.main_zone
}
