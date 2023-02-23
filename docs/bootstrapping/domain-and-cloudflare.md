# ドメインと Cloudflare のセットアップ

初めに、`kory33.net` を [Google Domains](https://domains.google.com/) にて、 @kory33 の個人用の Google アカウントを通して取得してください。

次に、 @kory33 の Cloudflare アカウントにて、 `kory33.net` を新しいサイトとして追加してください。Cloudflare の指示に従い、 Google Domain 上で、 `kory33.net` のカスタムネームサーバーを Cloudflare の name server に設定してください。

Cloudflare Zero Trust を利用するので、 Zero Trust の team domain を `kory33.cloudflareaccess.com` に設定してください。

また、Cloudflare Workers を利用するので、Workers の subdomain を `kory33.workers.dev` に設定してください。プランは Free プラン (2023/02/23 時点で 100K worker req/day と 100K KV read/day の利用を含む) で問題ありません。
