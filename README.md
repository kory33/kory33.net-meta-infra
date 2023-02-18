# kory33.net-meta-infra

[kory33.net-infra](https://github.com/kory33/kory33.net-infra) で管理されているインフラストラクチャをブートストラップ及びリカバリするための手順やスクリプト、並びに、それらインフラストラクチャの基盤部分の Terraform 等による定義を管理するリポジトリです。

---

目次

- [文書に関するメタな情報](#文書に関するメタな情報)
  - [ドキュメント内の自由変数](#ドキュメント内の自由変数)
- [当リポジトリが管理を担当するインフラストラクチャ](#当リポジトリが管理を担当するインフラストラクチャ)
  - [keyless SSH について](#keyless-ssh-について)
  - [前述の keyless SSH のセットアップのセキュリティについて](#前述の-keyless-ssh-のセットアップのセキュリティについて)
  - [なぜ Short-lived certificate を利用しないのか？](#なぜ-short-lived-certificate-を利用しないのか)
  - [SSHD へのアクセス制限](#SSHD-へのアクセス制限)
- [cloud-init の処理内容と `establish tunnel` のステップについて](#cloud-init-の処理内容と-establish-tunnel-のステップについて)
- [`ssh--admin.kory33.net` で繋がるマシンの正当性の根拠](#ssh--adminkory33net-で繋がるマシンの正当性の根拠)
- [各種セットアップ手順](#各種セットアップ手順)

---

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

次に続くのサブセクションでは、上記の図に関連する注意点を説明します。インフラストラクチャ運用する前に、必ず以下の注意点のすべての点を理解してください (**MUST**)。

### keyless SSH について

`ssh--admin.kory33.net` に (正当に) アクセスする GitHub Actions は `kory33/kory33.net-infra` の `main` ブランチのものに限られるため、これ以外の Actions からのアクセスを拒否します。

期待する Action によるアクセスであることは、GitHub Actions の identity provider が提供する OpenID Connect の JWKS を検証することで確認できます (詳しくは [About security hardening with OpenID Connect](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect) を参照してください)。この一連の検証ルールは Terraform Cloud が管理することとなる access policy に組み込まれます。

`ssh--admin.kory33.net` への認証は完全に Cloudflare Access にオフロードし、インスタンス側ではユーザーの正当性を検証しないことにします。つまり、インスタンス上での `ubuntu` ユーザー (OCI Compute Instance 向け Ubuntu イメージでデフォルト生成される唯一の sudoer) のパスワードを削除し、 SSHD に空パスワードによる認証を受け付けさせ、**インスタンスの SSHD に到達できていることをユーザーの正当性の根拠とします**。

#### 前述の keyless SSH のセットアップのセキュリティについて

Cloudflare が提供する [short-lived certificate](https://developers.cloudflare.com/cloudflare-one/identity/users/short-lived-certificates) の機能は利用せず、`cloudflared access ssh --hostname ssh--admin.kory33.net` にてトンネルをローカルに張る瞬間に、 Cloudflare の認証基盤を利用してユーザーの正当性を検証します。
short-lived certificate を利用しないことによるセキュリティ上不利な点として、

- インスタンス内のユーザーにどの Principal がアクセスできるかの詳細な制御ができない
- インスタンス側のログで、どの Principal が実際にアクセスしてきているかの情報が取れない

の二点が挙げられます。しかしながら、当インフラストラクチャでは Principal が二つ (マシンユーザーである GitHub Actions と 管理者である [@kory33](https://github.com/kory33)) しか存在しないうえ、どちらの Principal も `ubuntu` ユーザー (OCI Compute Instance 上で生成される唯一の sudoer user) へのアクセスが許されているため、この二点はユーザー側で認証情報を管理しなければならないことの運用負荷と天秤に掛ければ、許容できるとの判断をしました。

#### なぜ Short-lived certificate を利用しないのか？

Short-lived certificate を利用せずにこのような設計を取っている理由は、 2023/02/18 現在、`cloudflared` にマシンユーザーによる SSH ログインを行う時に Principal を指定できる機能 ([cloudflared#212](https://github.com/cloudflare/cloudflared/issues/212)) が実装されていないためです。この機能が無い限り、GitHub Actions ワークフローに、 GitHub Actions IdP が発行する OIDC Claim を根拠とする short-lived certificate を利用して SSH をさせる、ということが叶いません。

もし、署名付きの JWT に渡される Principal に OIDC Claim から得られた認証情報を結びつける機能が Cloudflare 側で実装されれば、その機能を利用した認証方法に切り替えるべきです。

一連の short-lived certificate による認証基盤は、原理的には Cloudflare Worker を利用して自前で再現できるものになっているはずですが、 JWT の発行、署名と CA 証明書管理を行うアプリケーションのソースコードが (2023/02/18 現在) 公開されていないため、自前構築を断念しています。一連の仕組みについての詳しい解説は [Public keys are not enough for SSH security - The Cloudflare Blog](https://blog.cloudflare.com/public-keys-are-not-enough-for-ssh-security/) を参照してください。

#### SSHD へのアクセス制限

上記で説明した設計により、`cloudflared` 以外の**一切の**プロセスからの `sshd` への接続を拒否する必要があります。

これを実現するため、`cloudflared` を `cloudflared-proxy-user` と名付けた (non-sudoer) ユーザーの元で動作させ、`iptables` にて `cloudflared-proxy-user` 以外からの `lo:22` (SSHD が listen しているポート) へのアクセスを遮断するようにします。如何なる状況においてもこの制約を緩めないでください (**MUST NOT**)。

また、Kubernetes クラスタ内のすべてのプログラムを完全に信頼することは困難なため、 Kubernetes クラスタは必ず

- [rootless mode](https://kubernetes.io/docs/tasks/administer-cluster/kubelet-in-userns/) で
- `cloudflared-proxy-user` 以外の non-sudoer ユーザーの権限で
- 適切な container isolation を有効化して

実行してください (**MUST**)。

### cloud-init の処理内容と `establish tunnel` のステップについて

OCI Compute Instance に送付する cloud-init スクリプトは、インスタンスがリブートされるたびに実行されるようにします。このスクリプトは、大まかに以下の事を行います。

- [OCI CLI](https://docs.oracle.com/en-us/iaas/Content/API/Concepts/cliconcepts.htm) をインストールする
- OCI Vault に入っている tunnel credential を OCI CLI により (instance principal を認証に使うことで) 取得する
- (前述の通り、認証を完全に Cloudflare にオフロードするために) SSHD の認証を切り、サービスを再起動する
- [`cloudflared`](https://github.com/cloudflare/cloudflared) の特定バージョンを (まだダウンロードされていなければ) ダウンロードする
- `ssh--admin.kory33.net` に作成されている Cloudflare Tunnel を (スクリプトが実行されている) インスタンスに向ける

cloud-init スクリプトが正常に動作し終えた時点で、[@kory33](https://github.com/kory33) と特定の GitHub Actions ワークフローが、インターネットを通して keyless SSH でインスタンスに接続できることを期待します。

### `ssh--admin.kory33.net` で繋がるマシンの正当性の根拠

Terraform によって OCI Vault に共有される tunnel credential のことを、**SSH Tunnel Credential** と呼ぶことにします。

`ssh--admin.kory33.net` が我々が作成したインスタンスであるという確証は、SSH Tunnel Credential が漏洩していないことに依存します。

SSH Tunnel Credential は、正当なインスタンス内からであれば OCI Vault からいつでも読み取れるようになっています。インスタンス内にホストされる Kubernetes クラスタ内のすべてのプログラムを完全に信頼することは困難なため、Kubernetes クラスタ内のプログラムが SSH Tunnel Credential にアクセスできないように十分な注意を払う必要があります。

インスタンス内で OCI Vault から SSH Tunnel Credential を読み取るためには、 OCI Compute Instance の Metadata API (`169.254.169.254`) へアクセスして認証情報を取得することが必要となっています。 cloud-init が `ubuntu` ユーザーによって cloudflared を設定する場面以外で Metadata API へのアクセスが発生することは**無い**と仮定します。よって、 `ubuntu` 以外のユーザーから `169.254.169.254` (metadata API) へのアクセスを `iptables` を用いて必ず遮断するようにしてください (**MUST**)。クラスタ内にいかなる形でも SSH Tunnel Credential を露出しないでください (**MUST NOT**)。

自動化された GitHub Actions が誤って悪意あるインスタンスに接続することを防ぐために、インスタンスの初期設定が終わってすぐに、一度手動でローカルマシンからインスタンスに接続し、サーバーの fingerprint を確かめた上で、それを GitHub Actions に定数として共有する、という手順を踏む必要があります (**MUST**)。詳しい手順については、セットアップ手順で説明します。

## 各種セットアップ手順

- [ドメインと Cloudflare Zone のセットアップ](./docs/bootstrapping/domain-and-cloudflare-zone.md)
- [Oracle Cloud Infrastructure の Compute Instance セットアップ](./docs/bootstrapping/oci-compute-instances.md)
