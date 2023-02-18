# ドメインと Cloudflare Zone のセットアップ

初めに、`kory33.net` を [Google Domains](https://domains.google.com/) にて、 @kory33 の個人用の Google アカウントを通して取得してください。

次に、 @kory33 の Cloudflare アカウントにて、 `kory33.net` を新しいサイトとして追加してください。Cloudflare の指示に従い、 Google Domain 上で、 `kory33.net` のカスタムネームサーバーを Cloudflare の name server に設定してください。

Cloudflare Zero Trust を利用するので、 Zero Trust の team domain を `kory33.cloudflareaccess.com` に設定してください。
