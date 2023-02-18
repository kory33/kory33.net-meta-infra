# kory33.net-meta-infra

[kory33.net-infra](https://github.com/kory33/kory33.net-infra) で管理されているインフラストラクチャをブートストラップ及びリカバリするための手順やスクリプト、並びに、それらインフラストラクチャの基盤部分の Terraform 等による定義を管理するリポジトリです。

- [文書に関するメタな情報](#文書に関するメタな情報)
  - [ドキュメント内の自由変数](#ドキュメント内の自由変数)
- [当リポジトリが管理を担当するインフラストラクチャ](#当リポジトリが管理を担当するインフラストラクチャ)

## 文書に関するメタな情報

当リポジトリ内のドキュメントは、 (未来の) [@kory33](https://github.com/kory33) に向けた作業手順やリファレンスとして機能することを想定しています。ドキュメントを読み書きする作業者に対して何らかの行為を推奨及び指示する際には、この文がそうしているように、語り掛ける文体で記述してください。

この文書は公開されることを想定して記述してください。したがって、公開することによってサービスのホストが容易に著しく妨害される可能性のある情報は、いかなる形であっても当文書から参照できる形で残さないようにしてください。

図などをドキュメントに含める際には、 [app.diagrams.net](https://app.diagrams.net/) で読み込むことができる svg ファイルを利用してください。それらの編集作業は、VSCode 上で [Draw.io VS Code Integration](https://github.com/hediet/vscode-drawio) を用いて行うことを推奨します。

もしあなたが [@kory33](https://github.com/kory33) 以外の第三者で、当リポジトリのドキュメントの誤字脱字やフォーマット、あるいは当リポジトリが定義するインフラストラクチャの構成の改善に関してご意見がある場合、 [Issue](https://github.com/kory33/kory33.net-meta-infra/issues) 及び [Pull Request](https://github.com/kory33/kory33.net-meta-infra/pulls) を開いていただくか、Kory#4933 (Discord) または [@Kory\_\_3@twitter.com](https://twitter.com/Kory__3) へ連絡していただき、概要をお伝えくださると幸いです。

万が一セキュリティ上の脆弱性が発覚した場合、Kory#4933 (Discord) または [@Kory\_\_3@twitter.com](https://twitter.com/Kory__3) へ報告をお願いいたします。

### ドキュメント内の自由変数

当リポジトリ内にドキュメントに現れる以下の概念は、「どのエンティティを指しているかが [@kory33](https://github.com/kory33) の中では明らかである」特定のエンティティを表しています。

- [@kory33](https://github.com/kory33) の個人用の Google アカウント
- [@kory33](https://github.com/kory33) の Cloudflare アカウント
- [@kory33](https://github.com/kory33) の Terraform Cloud アカウント
- [@kory33](https://github.com/kory33) の Oracle Cloud Infrastructure アカウント

もしあなたが [@kory33](https://github.com/kory33) 以外の第三者で、当リポジトリが定義するインフラストラクチャ構成を模倣してインフラストラクチャ群をセットアップしたい場合は、適切な代替となるエンティティへと読み替えてください。

## 当リポジトリが管理を担当するインフラストラクチャ

kory33.net には様々なサービスがホストされることが想定されています。当リポジトリでは、これらサービスの継続的なバージョンアップや CI/CD などを担当するためのソフトウェアインフラストラクチャのことを**サービスレイヤインフラストラクチャ**、サービスレイヤインフラストラクチャをホストし、外部から操作可能にするための一連のクラウドインフラストラクチャの事を**基盤インフラストラクチャ**と呼んで区別することとします。

当リポジトリは、手作業と Terraform Cloud による基盤インフラストラクチャの管理を目的としています。サービスレイヤインフラストラクチャには [Docker](https://www.docker.com/) + [Kubernetes](https://kubernetes.io/) + [ArgoCD](https://argoproj.github.io/cd/) の技術スタックを想定していますが、当レポジトリではこれらにほとんど関与せず、 [kory33.net-infra](https://github.com/kory33/kory33.net-infra) に管理を一任します。

当リポジトリで管理を行うインフラストラクチャの全体図を図示します。当リポジトリのセットアップ手順を完了し、 Terraform Cloud 上で Terraform スクリプトが (適切なシークレットとともに) 実行され終わったとき、次のようなインフラストラクチャが得られていることが期待されます。

![overview](docs/diagrams/overview.drawio.svg)

上記の図に関連する注意点は以下の通りです:

### cloud-init の処理内容と `establish tunnel` のステップについて

OCI Compute Instance に送付する cloud-init スクリプトは、インスタンスがリブートされるたびに実行されるようにします。このスクリプトは、大まかに以下の事を行います。

- [OCI CLI](https://docs.oracle.com/en-us/iaas/Content/API/Concepts/cliconcepts.htm) をインストールする
- OCI Vault に入っている tunnel credential を OCI CLI により (instance principal を認証に使うことで) 取得する
- SSHD が short-lived certificate を利用するように[設定](https://developers.cloudflare.com/cloudflare-one/identity/users/short-lived-certificates)し、サービスを再起動する
  - ここで利用する CA 公開鍵は、Terraform により作成し、OCI Vault に格納します。この値は秘匿性が無いため、緩い権限設定でも構いません (MAY)。
- [`cloudflared`](https://github.com/cloudflare/cloudflared) の特定バージョンを (まだダウンロードされていなければ) ダウンロードする
- `ssh--admin.kory33.net` に作成されている Cloudflare Tunnel を (スクリプトが実行されている) インスタンスに向ける

cloud-init スクリプトが正常に動作し終えた時点で、[@kory33](https://github.com/kory33) と特定の GitHub Actions ワークフローが、インターネットを通して keyless SSH でインスタンスに接続できることを期待します。

### keyless SSH について

`ssh--admin.kory33.net` に (正当に) アクセスする GitHub Actions は `kory33/kory33.net-infra` の `main` ブランチのものに限られるため、これ以外の Actions からのアクセスを拒否します。

期待する Action によるアクセスであることは、GitHub Actions の identity provider が提供する OpenID Connect の JWKS を検証することで確認できます (詳しくは [About security hardening with OpenID Connect](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect) を参照してください)。この一連の検証ルールは Terraform Cloud が管理することとなる access policy に組み込まれます。

(検証 TODO): この machine access の SSH ユーザー名はいったいどうなる？cloud-init 側でユーザーを用意しておく必要がある？そもそも email アドレス無しに Cloudflare Tunnel を通して SSH アクセスが可能なのか？

### `ssh--admin.kory33.net` の正当性の根拠

Terraform によって OCI Vault に共有される tunnel credential のことを、**SSH Tunnel Credential** と呼ぶことにします。

`ssh--admin.kory33.net` が我々が作成したインスタンスであるという確証は、SSH Tunnel Credential が漏洩していないことに依存します。

SSH Tunnel Credential は、正当なインスタンス内からであれば OCI Vault からいつでも読み取れるようになっています。一方、インスタンスには Kubernetes クラスタがホストされ、その上で様々なプログラムが動くことが想定されるため、Kubernetes クラスタ内のプログラムが SSH Tunnel Credential にアクセスできないように十分な注意を払う必要があります。

インスタンス内で OCI Vault から SSH Tunnel Credential を読み取るためには、 OCI Compute Instance の Metadata API (`169.254.169.254`) へアクセスして認証情報を取得することが必要となっています。よって、インスタンス内にホストする Kubernetes クラスタでは、クラスタ内すべての pod から `169.254.169.254` (metadata API) へのアクセスを必ず遮断するようにしてください (**MUST**)。クラスタ内にいかなる形でも SSH Tunnel Credential を露出しないでください (**MUST NOT**)。

自動化された GitHub Actions が誤って悪意あるインスタンスに接続することを防ぐために、インスタンスの初期設定が終わってすぐに、一度手動でローカルマシンからインスタンスに接続し、サーバーの fingerprint を確かめた上で、それを GitHub Actions に定数として共有する、という手順を踏む必要があります (**MUST**)。詳しい手順については、セットアップ手順で説明します。

## 各種セットアップ手順

- [ドメインと Cloudflare Zone のセットアップ](./docs/bootstrapping/domain-and-cloudflare-zone.md)
- [Oracle Cloud Infrastructure の Compute Instance セットアップ](./docs/bootstrapping/oci-compute-instances.md)
