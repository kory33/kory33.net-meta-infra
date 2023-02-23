# kory33.net-meta-infra

[kory33.net-infra](https://github.com/kory33/kory33.net-infra) で管理されているインフラストラクチャをブートストラップ及びリカバリするための手順やスクリプト、並びに、それらインフラストラクチャの基盤部分の Terraform 等による定義を管理するリポジトリです。

---

目次

- [概要](#概要)
  - [ドキュメント内の自由変数](#ドキュメント内の自由変数)
- [インフラストラクチャの概要](#インフラストラクチャの概要)
  - [GitHub Actions によるアクセスで Short-lived certificate を利用しない理由](#gitHub-actions-によるアクセスで-short-lived-certificate-を利用しない理由)
  - [`ssh--admin.kory33.net` で繋がるマシンの正当性の根拠](#ssh--admin-kory33-net-で繋がるマシンの正当性の根拠)
  - [cloud-init の処理内容について](#cloud-init-の処理内容について)
- [各種セットアップ手順](#各種セットアップ手順)

---

## 概要

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

## インフラストラクチャの概要

当リポジトリのドキュメントにおいては、以下のように用語を定義します。

- **サービスレイヤインフラストラクチャ**: `kory33.net` にホストされる様々なサービスの継続的なバージョンアップや、CI/CD などを実現するためのソフトウェアインフラストラクチャ。
- **基盤インフラストラクチャ**: サービスレイヤインフラストラクチャをホストし、外部から操作可能にするための一連のクラウドインフラストラクチャ。

当リポジトリは、手作業と Terraform Cloud による基盤インフラストラクチャの管理を目的としています。サービスレイヤインフラストラクチャには [Docker](https://www.docker.com/) + [Kubernetes](https://kubernetes.io/) + [ArgoCD](https://argoproj.github.io/cd/) の技術スタックを想定していますが、当レポジトリではこれらにほとんど関与せず、 [kory33.net-infra](https://github.com/kory33/kory33.net-infra) に管理を一任します。

当リポジトリで管理を行うインフラストラクチャの全体図を図示します。当リポジトリのセットアップ手順を完了し、 Terraform Cloud 上で Terraform スクリプトが (適切なシークレットとともに) 実行され終わったとき、次のようなインフラストラクチャが構築できていることが期待されます。

![overview](docs/diagrams/overview.drawio.svg)

上の図で示されている SSH 用の Cloudflare Tunnel は、インターネットからの SSH サーバーへのアクセスを最小限に絞り、SSH サーバーの運用をより安全にする役割を持ちます。この Cloudflare Tunnel は、管理者 ([@kory33](https://github.com/kory33)) と `kory33/kory33.net-infra` 内の特定の GitHub Actions Workflow のみがトンネリングできるように設定します。

管理者は、OCI Compute Instance に対して、次の図に示されるような認証フローを用いて SSH セッションを確立できます。

![Administrator SSH connection flow diagram](docs/diagrams/administrator-ssh-connection.drawio.svg)

アクセスを許可された GitHub Actions Workflow は、OCI Compute Instance に対して、次の図に示されるような認証フローを用いて SSH セッションを確立できます。

![GitHub Actions Workflow SSH connection flow diagram](docs/diagrams/gha-ssh-connection.drawio.svg)

次に続くサブセクションでは、上記の構成に関してインフラストラクチャ管理者が知っておく必要がある注意点を説明します。**インフラストラクチャを運用・管理する前に、必ず以下の注意点のすべての点に目を通し、理解するようにしてください。**

### GitHub Actions によるアクセスで Short-lived certificate を利用しない理由

GitHub Actions によるアクセスにおいて Short-lived certificate を利用していない理由は、 2023/02/18 現在、`cloudflared ssh-gen` に特定の (認証情報に紐づいた) ユーザー名を指定できる機能 ([cloudflared#212](https://github.com/cloudflare/cloudflared/issues/212)) が実装されていないためです。この機能が無い限り、 GitHub Actions IdP が発行する JWT Claim を根拠とする short-lived certificate を利用して GitHub Actions ワークフローに SSH をさせる、ということが叶いません。また、そもそも、Cloudflare Access への認証を JWT で行う機能が Cloudflare にネイティブ機能としては実装されていません (代わりに Worker を用いて特定のルールセットを検証することは可能です)。

そのため、現状は

- Cloudflare Tunnel へのアクセスは [`tsndr/cloudflare-worker-jwt`](https://github.com/tsndr/cloudflare-worker-jwt) を利用した、 Cloudflare Workers にオフロードされた認証で、
- SSH 先のインスタンスの SSHD へのアクセスは [`salesforce/pam_oidc`](https://github.com/salesforce/pam_oidc) を利用した、PAM (Pluggable Authentication Module) による認証で

それぞれ GitHub Actions IdP から得られる JWT を検証させるようにしています。

もし、署名付きの JWT に渡される Principal に OIDC Claim から得られた認証情報を結びつける機能が Cloudflare / `cloudflared` で実装されれば、認証フローの単純化のために、その機能を利用した認証方法に切り替えるべきです。

一連の short-lived certificate による認証基盤は、原理的には Cloudflare Worker を利用して自前で再現できるものになっているはずですが、 JWT の発行、署名と CA 証明書管理を行うアプリケーションのソースコードが (2023/02/18 現在) 公開されていないため、自前構築を断念しています。一連の仕組みについての詳しい解説は [Public keys are not enough for SSH security - The Cloudflare Blog](https://blog.cloudflare.com/public-keys-are-not-enough-for-ssh-security/) を参照してください。

### `ssh--admin.kory33.net` で繋がるマシンの正当性の根拠

Terraform によって OCI Vault に共有される tunnel credential のことを、**SSH Tunnel Credential** と呼ぶことにします。

`ssh--admin.kory33.net` が我々が作成したインスタンスであるという確証は、SSH Tunnel Credential が漏洩していないことに依存します。インスタンス内にホストされる Kubernetes クラスタ内のすべてのプログラムを完全に信頼することは困難なため、Kubernetes クラスタ内のプログラムが SSH Tunnel Credential にアクセスできないように十分な注意を払う必要があります。

SSH Tunnel Credential は、正当なインスタンス内からであれば、次の手順で OCI Vault から読み取れます。

- OCI Compute Instance の Metadata API (`http://169.254.169.254/opc/v2/identity`) へアクセスして、インスタンス固有のクライアント証明書を取得する
- このクライアント証明書を利用して OCI Vault へ認証し、 SSH Tunnel Credential を読み出す

よって、cloud-init が `ubuntu` ユーザーによって cloudflared を設定する場面以外では Metadata API へのアクセスが発生することが**無い**と仮定する必要があります。この仮定を充足するため、次の制約を遵守してください。

- `ubuntu` 以外のユーザーから `169.254.169.254` (metadata API) へのアクセスを `iptables` を用いて必ず遮断してください (**MUST**)
- Kubernetes クラスタ内のすべてのプログラムを完全に信頼することは困難なため、 Kubernetes クラスタは必ず

  - [rootless mode](https://kubernetes.io/docs/tasks/administer-cluster/kubelet-in-userns/) で
  - `ubuntu` 以外の、権限が極めて制限されたユーザーの権限で
  - 適切な container isolation を有効化して

  実行してください(**MUST**)

- クラスタ内にいかなる形でも SSH Tunnel Credential を露出しないでください (**MUST NOT**)。

インスタンスの初期設定が終わってすぐに、一度手動でローカルマシンからインスタンスに接続し、サーバーの fingerprint を確かめた上で、それを GitHub Actions に定数として共有する、という手順を踏むことを強く推奨します (**SHOULD**)。これにより、自動化された GitHub Actions が誤って悪意あるインスタンスに接続することを防ぐことができます。

### cloud-init の処理内容について

OCI Compute Instance に送付する cloud-init スクリプトは、インスタンスがリブートされるたびに実行されるようにします。このスクリプトは、大まかに以下の事を行います。

- [OCI CLI](https://docs.oracle.com/en-us/iaas/Content/API/Concepts/cliconcepts.htm) をインストールする
- SSHD に [`salesforce/pam_oidc`](https://github.com/salesforce/pam_oidc) を利用させるように設定し、`TrustedCACert` を OCI Vault に入っている CA Cert に向け、各種設定を行う
- [`cloudflared`](https://github.com/cloudflare/cloudflared) の特定バージョンを (まだダウンロードされていなければ) ダウンロードする
- SSH Tunnel Credential を OCI CLI により (instance principal を認証に使うことで) 取得する
- `ssh--admin.kory33.net` に作成されている Cloudflare Tunnel を (スクリプトが実行されている) インスタンスに向ける

Terraform Cloud がリソース作成を実装し cloud-init スクリプトが正常に動作し終えた時点で、

- [@kory33](https://github.com/kory33) と特定の GitHub Actions ワークフローが、
- インターネットを通して、
- 証明書やパスワードなどの認証情報も接続先 IP アドレスも知っていない状態から
- Cloudflare を通して認証することで
- インスタンスに SSH 接続できる

ことを期待します。

## 各種セットアップ手順

次の手順に従うことで基盤インフラストラクチャ全体を立ち上げることができます。

- [ドメインと Cloudflare のセットアップ](./docs/bootstrapping/domain-and-cloudflare.md) に従って、ドメイン周りの設定を行う
- [Terraform Cloud とそれに持たせる認証情報の用意](./docs/bootstrapping/credentials-to-terraform-cloud.md) に従って、Terraform Cloud に Cloudflare や Oracle Cloud Infrastructure への認証情報を持たせる
- Terraform Cloud 上で plan + apply を実行する

サービスインフラストラクチャのセットアップは、サービスインフラストラクチャを管理している [kory33.net-infra](https://github.com/kory33/kory33.net-infra) を参照してください。
