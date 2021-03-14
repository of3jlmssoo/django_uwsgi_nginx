# reamde

kubernetes(minikube)で実行することを考えてk8s環境下のdockerで作業を行っていた。
ローカル環境のブラウザーからnginxへアクセスできない事態が続いたが、minikube tunnelが必要なだけだった。
## 参考にしたサイト
[コンテナ間通信の設定をkubernetesとdocker-composeで同じ構成で構築してみた（nginx <-> uWSGI <-> Flask）][4]

[4]:https://snowsystem.net/container/docker/same-env-build/

## 大まかな流れ

1. 上記サイトを参考に各種ファイルを準備する。ただしflaskではなくdjango前提
2. minikube start, eval $(minikube docker-env)してdocker-compose buildしたりupしたり
3. ローカル環境のブラウザからlocalhost:8000へアクセスするが接続拒否される(nginxへアクセスできない)
4. 色々確認したり試す。この中でdocker-compose run web django-admin.py startproject mysite .がエラーなく終了するが然るべきファイル(uwsgi.py)が作られない問題に直面する。これはdjaong-admin.pyをネイティブで実行することで回避
5. コンテナにログインしてみる。container.uwsgiへログインしてcontainer.nginxへcurlするとniginxが動いていて返答も返されていることが確認できる。container.nginxへログインしてcurlしても同様
6. minikube配下のdockerではなくネイティブのdockerで試したところlocalhost:8000でアクセスできる
7. minikube配下のdockerでminikube tunnelで表示されるアドレスに変更したところアクセスできるようになった
8. ここで一旦commit-m "docker version"
9. kompose

## メモ

- nginxはdocker execする時sh。uwsgiの方は/bin/bashが使える
- docker logs --timestamp container.nginx
- uwsgiの方は素直にuwsgi.iniで定義されたlogtoをコンテナにログイン後確認する
- nginx/uwsgiのつなぎはmysite_nginx.conf / uwsgi.ini / docker-compose.yaml
- niginxはポート8000, uwsgiはポート8001
- k8sでは、service for nginxは30081でリクエストを受けてtargetPort(nginx)は8000
  service for uwsgi/djangは8001でリクエストを受けてtargetPortも8001

## 今後

- ファイルの構成を検討する

kompose導入
別ウィンドウでkubectl tunnel --cleanup実行済み
kubectl apply -f my-network-networkpolicy.yaml,nginx-deployment.yaml,nginx-service.yaml,web-deployment.yaml,web-service.yaml
kubectl delete svc nginx
kubectl expose deployment nginx --type=LoadBalancer --port=8000
(py39) hiroshisakuma@hiroshisakuma-NUC10i7FNH:~/projects/minikube/basic/docker_django_alpha/kompose_work$ kubectl get all
NAME                         READY   STATUS    RESTARTS   AGE
pod/nginx-69b647dc5c-mlvlq   1/1     Running   0          2m6s
pod/web-58bfcf668b-bjg5f     1/1     Running   0          2m6s

NAME                 TYPE           CLUSTER-IP       EXTERNAL-IP   PORT(S)          AGE
service/kubernetes   ClusterIP      10.96.0.1        <none>        443/TCP          5d4h
service/nginx        LoadBalancer   10.106.150.117   <pending>     8000:30905/TCP   3s
service/web          ClusterIP      10.102.95.138    <none>        8001/TCP         2m6s

NAME                    READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/nginx   1/1     1            1           2m6s
deployment.apps/web     1/1     1            1           2m6s

NAME                               DESIRED   CURRENT   READY   AGE
replicaset.apps/nginx-69b647dc5c   1         1         1       2m6s
replicaset.apps/web-58bfcf668b     1         1         1       2m6s
(py39) hiroshisakuma@hiroshisakuma-NUC10i7FNH:~/projects/minikube/basic/docker_django_alpha/kompose_work$ kubectl get all
NAME                         READY   STATUS    RESTARTS   AGE
pod/nginx-69b647dc5c-mlvlq   1/1     Running   0          2m9s
pod/web-58bfcf668b-bjg5f     1/1     Running   0          2m9s

NAME                 TYPE           CLUSTER-IP       EXTERNAL-IP      PORT(S)          AGE
service/kubernetes   ClusterIP      10.96.0.1        <none>           443/TCP          5d4h
service/nginx        LoadBalancer   10.106.150.117   10.106.150.117   8000:30905/TCP   6s
service/web          ClusterIP      10.102.95.138    <none>           8001/TCP         2m9s

NAME                    READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/nginx   1/1     1            1           2m9s
deployment.apps/web     1/1     1            1           2m9s

NAME                               DESIRED   CURRENT   READY   AGE
replicaset.apps/nginx-69b647dc5c   1         1         1       2m9s
replicaset.apps/web-58bfcf668b     1         1         1       2m9s
(py39) hiroshisakuma@hiroshisakuma-NUC10i7FNH:~/projects/minikube/basic/docker_django_alpha/kompose_work$ 

(py39) hiroshisakuma@hiroshisakuma-NUC10i7FNH:~/projects/minikube/basic/docker_django_alpha/kompose_work$ curl http://10.106.150.117:8000    

<!doctype html>

<html>
    <head>
        <meta charset="utf-8">
        <title>Django: 納期を逃さない完璧主義者のためのWebフレームワーク</title>
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <link rel="stylesheet" type="text/css" href="/static/admin/css/fonts.css">

(py39) hiroshisakuma@hiroshisakuma-NUC10i7FNH:~/projects/minikube/basic/docker_django_alpha/kompose_work$ kubectl expose deployment nginx --type=NodePort --port 8000
service/nginx exposed
(py39) hiroshisakuma@hiroshisakuma-NUC10i7FNH:~/projects/minikube/basic/docker_django_alpha/kompose_work$ kubectl get all
NAME                         READY   STATUS    RESTARTS   AGE
pod/nginx-69b647dc5c-mlvlq   1/1     Running   0          102m
pod/web-58bfcf668b-bjg5f     1/1     Running   0          102m

NAME                 TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)          AGE
service/kubernetes   ClusterIP   10.96.0.1        <none>        443/TCP          5d5h
service/nginx        NodePort    10.104.163.101   <none>        8000:31740/TCP   15s
service/web          ClusterIP   10.102.95.138    <none>        8001/TCP         102m

NAME                    READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/nginx   1/1     1            1           102m
deployment.apps/web     1/1     1            1           102m

NAME                               DESIRED   CURRENT   READY   AGE
replicaset.apps/nginx-69b647dc5c   1         1         1       102m
replicaset.apps/web-58bfcf668b     1         1         1       102m
(py39) hiroshisakuma@hiroshisakuma-NUC10i7FNH:~/projects/minikube/basic/docker_django_alpha/kompose_work$ kubectl describe service/nginx
Name:                     nginx
Namespace:                default
Labels:                   io.kompose.service=nginx
Annotations:              <none>
Selector:                 io.kompose.service=nginx
Type:                     NodePort
IP Families:              <none>
IP:                       10.104.163.101
IPs:                      10.104.163.101
Port:                     <unset>  8000/TCP
TargetPort:               8000/TCP
NodePort:                 <unset>  31740/TCP
Endpoints:                172.17.0.6:8000
Session Affinity:         None
External Traffic Policy:  Cluster
Events:                   <none>
(py39) hiroshisakuma@hiroshisakuma-NUC10i7FNH:~/projects/minikube/basic/docker_django_alpha/kompose_work$ minikube ip
192.168.59.2
curl http://192.168.59.2:31740
curl http://10.104.163.101:8000


## フロー
docker-compose build --no-cache
docker-compose up

minikube start
eval $(minikube docker-env)

nginx = nordportのケース
kubectl describe service nginx
  NodePort:                 <unset>  31740/TCP
minikube ip    or     kubectl cluster-info
  192.168.59.2
curl http://192.168.59.2:31740

nodeportでの外部IPアドレスの確認方法は環境に依存する、と[ここ][142]に書いてある。IBM Cloudの場合、以下のコマンドで確認できると[ここ][143]に書いてある。

```text
ibmcloud ks worker ls --cluster <cluster_name>
```

一旦、service nginxを削除する
kubectl delete service nginx


curl http://192.168.59.2:31740
curl: (7) Failed to connect to 192.168.59.2 port 31740: 接続を拒否されました

kubectl apply -f ./nginx_nordport_service.yaml
curl http://192.168.59.2:31740
接続できる。

次は、loadbalancerのケース
kubectl delete service nginx
kubectl expose deployment nginx --type=LoadBalancer --port=8000
kubectl get service nginx
EXTERNAL-IPがpendingであり続ける
minikube tunnel --cleanup
kubectl get service nginx
  NAME    TYPE           CLUSTER-IP       EXTERNAL-IP      PORT(S)          AGE
  nginx   LoadBalancer   10.101.127.214   10.101.127.214   8000:32547/TCP   3m12s
curl http://10.101.127.214:8000

kubectl delete service nginx
kubectl get service nginx
kubectl apply -f ./nginx_loadbalancer_service.yaml
kubectl get service nginx
NAME    TYPE           CLUSTER-IP       EXTERNAL-IP      PORT(S)          AGE
nginx   LoadBalancer   10.111.213.215   10.111.213.215   8000:31285/TCP   84s
curl http://10.111.213.215:8000


[142]:https://kubernetes.io/ja/docs/tasks/access-application-cluster/service-access-application-clusteNAL-IP
[143]:https://cloud.ibm.com/docs/containers?topic=containers-nodeport&locale=ja