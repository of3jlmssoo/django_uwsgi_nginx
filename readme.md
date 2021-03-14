# reamde

- nginx+uwsgi+djangoの組み合わせ
- まずdocker環境で実行
- その後minikube環境で実行。minikubeではNodePortとLoadBalancerの両方を試す
  - minikube環境に移す際にはkomposeコマンドを利用
  - ただし、nginxのserviceについてはkomposeの作成したものではなく個別に対応

## 参考にしたサイト
[コンテナ間通信の設定をkubernetesとdocker-composeで同じ構成で構築してみた（nginx <-> uWSGI <-> Flask）][4]

## 今後

- ファイルの構成を検討する

## dockerネイティブ環境での実行

```text
docker-compose build --no-cache
docker-compose up
```

## minikube環境での実行

```text
minikube start
eval $(minikube docker-env)
```

### NodePortのケース

```text
kubectl describe service nginx
  NodePort:                 <unset>  31740/TCP
minikube ip    or     kubectl cluster-info
  192.168.59.2
curl http://192.168.59.2:31740
```

nodeportでの外部IPアドレスの確認方法は環境に依存する、と[ここ][142]に書いてある。IBM Cloudの場合、以下のコマンドで確認できると[ここ][143]に書いてある。

```text
ibmcloud ks worker ls --cluster <cluster_name>
```

一旦、service nginxを削除してkubectl applyで作成し直す。

```text
kubectl delete service nginx

curl http://192.168.59.2:31740
curl: (7) Failed to connect to 192.168.59.2 port 31740: 接続を拒否されました

kubectl apply -f ./nginx_nordport_service.yaml
curl http://192.168.59.2:31740
```

接続できる。

### LoadBalancerのケース

```text
kubectl delete service nginx
kubectl expose deployment nginx --type=LoadBalancer --port=8000
kubectl get service nginx
```

この段階でEXTERNAL-IPがpendingであり続ける。minikube tunnelでIPアドレスがアサインされる。その後yamlファイルでapplyする。

```text
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
```
## メモ

- nginxはdocker execする時sh。uwsgiの方は/bin/bashが使える
- docker logs --timestamp container.nginx
- kubectl lgos pod-name
- kubectl describe pod-name
- docker/kubectl exec name (--) sh/bash
- curl http://web:8000  or  curl http://nginx:8000
- uwsgiの方は素直にuwsgi.iniで定義されたlogtoをコンテナにログイン後確認する
- nginx/uwsgiのつなぎはmysite_nginx.conf / uwsgi.ini / docker-compose.yaml
- kompose convert -f docker-compose.yaml
    - kubectl apply -f komoose1.yaml,komose2.yaml,kompose3.yaml
- minikube tunnel --cleanup
- minikube ip
- kubectl expose deployment nginx --type=LoadBalancer --port=8000

- kubectl get all 
  ```text
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
    ```

- kubectl expose deployment nginx --type=NodePort --port 8000
- kubectl get all
    ```text
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
    ```

- kubectl describe service/nginx

    ```text
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
    ```

### 環境
```text
$ lsb_release -a
No LSB modules are available.
Distributor ID: Ubuntu
Description:    Ubuntu 20.04.2 LTS
Release:        20.04
Codename:       focal
$ docker --version
Docker version 20.10.5, build 55c4c88
$ minikube version
minikube version: v1.18.1
commit: 09ee84d530de4a92f00f1c5dbc34cead092b95bc
$ kubectl version
Client Version: version.Info{Major:"1", Minor:"20", GitVersion:"v1.20.4", GitCommit:"e87da0bd6e03ec3fea7933c4b5263d151aafd07c", GitTreeState:"clean", BuildDate:"2021-02-18T16:12:00Z", GoVersion:"go1.15.8", Compiler:"gc", Platform:"linux/amd64"}
Server Version: version.Info{Major:"1", Minor:"20", GitVersion:"v1.20.2", GitCommit:"faecb196815e248d3ecfb03c680a4507229c2a56", GitTreeState:"clean", BuildDate:"2021-01-13T13:20:00Z", GoVersion:"go1.15.5", Compiler:"gc", Platform:"linux/amd64"}
```

[4]:https://snowsystem.net/container/docker/same-env-build/
[142]:https://kubernetes.io/ja/docs/tasks/access-application-cluster/service-access-application-clusteNAL-IP
[143]:https://cloud.ibm.com/docs/containers?topic=containers-nodeport&locale=jag