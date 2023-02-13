# kory33.net-meta-infra

[kory33.net-infra](https://github.com/kory33/kory33.net-infra) で管理されているインフラストラクチャをブートストラップ及びリカバリするための手順やスクリプト、並びに、それらインフラストラクチャの基盤部分の Terraform 等による定義を管理するリポジトリです。

- [文書に関するメタな情報](#文書に関するメタな情報)
  - [ドキュメント内の自由変数](#ドキュメント内の自由変数)
- [当リポジトリが管理を担当するインフラストラクチャ](#当リポジトリが管理を担当するインフラストラクチャ)

## 文書に関するメタな情報

当リポジトリ内のドキュメントは、 (未来の) @kory33 に向けた作業手順やリファレンスとして機能することを想定しています。ドキュメントを読み書きする作業者に対して何らかの行為を推奨及び指示する際には、この文がそうしているように、語り掛ける文体で記述してください。

この文書は公開されることを想定して記述してください。したがって、公開することによってサービスのホストが容易に著しく妨害される可能性のある情報は、いかなる形であっても当文書から参照できる形で残さないようにしてください。

図などをドキュメントに含める際には、 [app.diagrams.net](https://app.diagrams.net/) で読み込むことができる svg ファイルを利用してください。それらの編集作業は、VSCode 上で [Draw.io VS Code Integration](https://github.com/hediet/vscode-drawio) を用いて行うことを推奨します。

もしあなたが @kory33 以外の第三者で、当リポジトリのドキュメントの誤字脱字やフォーマット、あるいは当リポジトリが定義するインフラストラクチャの構成の改善に関してご意見がある場合、 [Issue](https://github.com/kory33/kory33.net-meta-infra/issues) 及び [Pull Request](https://github.com/kory33/kory33.net-meta-infra/pulls) を開いていただくか、Kory#4933 (Discord) または [@Kory\_\_3@twitter.com](https://twitter.com/Kory__3) へ連絡していただき、概要をお伝えくださると幸いです。

万が一セキュリティ上の脆弱性が発覚した場合、Kory#4933 (Discord) または [@Kory\_\_3@twitter.com](https://twitter.com/Kory__3) へ報告をお願いいたします。

### ドキュメント内の自由変数

当リポジトリ内にドキュメントに現れる以下の概念は、「どのエンティティを指しているかが @kory33 の中では明らかである」特定のエンティティを表しています。

- @kory33 の個人用の Google アカウント
- @kory33 の Cloudflare アカウント
- @kory33 の Terraform Cloud アカウント
- @kory33 の Oracle Cloud Infrastructure アカウント

もしあなたが @kory33 以外の第三者で、当リポジトリが定義するインフラストラクチャ構成を模倣してインフラストラクチャ群をセットアップしたい場合は、適切な代替となるエンティティへと読み替えてください。

## 当リポジトリが管理を担当するインフラストラクチャ

kory33.net には様々なサービスがホストされることが想定されています。当リポジトリでは、これらサービスの継続的なバージョンアップや CI/CD などを担当するためのソフトウェアインフラストラクチャのことを**サービスレイヤインフラストラクチャ**、サービスレイヤインフラストラクチャをホストし、外部から操作可能にするための一連のクラウドインフラストラクチャの事を**基盤インフラストラクチャ**と呼んで区別することとします。

当リポジトリは、手作業と Terraform Cloud による基盤インフラストラクチャの管理を目的としています。サービスレイヤインフラストラクチャには [Docker](https://www.docker.com/) + [Kubernetes](https://kubernetes.io/) + [ArgoCD](https://argoproj.github.io/cd/) の技術スタックを想定していますが、当レポジトリではこれらにほとんど関与せず、 [kory33.net-infra](https://github.com/kory33/kory33.net-infra) に管理を一任します。

以下に、当リポジトリで管理を行うインフラストラクチャの全体図を示します。

(TODO: 図を挿入する。当リポジトリでは手作業によるセットアップと Terraform Cloud による基盤インフラストラクチャの管理のみを担当し、その上に乗るソフトウェアに関しては、 `sshd` とそれに刺さりに行くように設定された `cloudflared` に関して以外一切関与しないことを説明する。また、 s3 等のバックアップストレージとの OIDC による接続などもこちら側で管理することを説明する。(TODO: どうやってコンテナの identity を証明すればよい？ Oracle Cloud Infrastructure は compute instance に identity を与える IdP を持っているか？)):

## 各種セットアップ手順

- [ドメインと Cloudflare Zone のセットアップ](./docs/bootstrapping/domain-and-cloudflare-zone.md)
- [Oracle Cloud Infrastructure の Compute Instance セットアップ](./docs/bootstrapping/oci-compute-instances.md)
