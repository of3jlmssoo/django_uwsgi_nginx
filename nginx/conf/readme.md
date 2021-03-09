# reamde

参考にしたサイト

kubernetes(minikube)で実行することを考えてk8s環境下のdockerで作業を行っていた。
ローカル環境のブラウザーからnginxへアクセスできない事態が続いたが、minikube tunnelが必要なだけだった。

## 大まかな流れ

1. 上記サイトを参考に各種ファイルを準備する。ただしflaskではなくdjango前提
2. minikube start, eval $(minikube docker-env)してdocker-compose buildしたりupしたり
3. ローカル環境のブラウザからlocalhost:8000へアクセスするが接続拒否される(nginxへアクセスできない)
4. 色々確認したり試す。この中でdocker-compose run sweb django-admin.py startproject mysite .がエラーなく終了するが然るべきファイル(uwsgi.py)が作られない問題に直面する。これはdjaong-admin.pyをネイティブで実行することで回避
5. コンテナにログインしてみる。container.uwsgiへログインしてcontainer.nginxへcurlするとniginxが動いていて返答も返されていることが確認できる。container.nginxへログインしてcurlしても同様
6. minikube配下のdockerではなくネイティブのdockerで試したところlocalhost:8000でアクセスできる
7. minikube配下のdockerでminikube tunnelで表示されるアドレスに変更したところアクセスできるようになった
8. ここで一旦commit-m "docker version"

## メモ

- nginxはdocker execする時sh。uwsgiの方は/bin/bashが使える
- docker logs --timestamp container.nginx
- uwsgiの方は素直にuwsgi.iniで定義されたlogtoをコンテナにログイン後確認する
- nginx/uwsgiのつなぎはmysite_nginx.conf / uwsgi.ini / docker-compose.yaml

## 今後
- ファイルの構成を検討する