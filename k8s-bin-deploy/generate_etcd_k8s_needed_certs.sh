CERT_BUILD_DIR=/opt/tools/k8s/k8s-ha-install/pki
ETCD_SSL_DIR=/opt/tools/etcd/ssl/
K8S_PKI_DIR=/opt/tools/k8s/pki/
ETH0_IP=172.29.52.196
K8S_API_PORT=6443
K8S_CONF_DIR=/opt/tools/k8s/conf/

cd $CERT_BUILD_DIR
cd ..
git clone https://github.com/dotbalo/k8s-ha-install.git
cd $CERT_BUILD_DIR
git checkout manual-installation-v1.21.x


# 生成etcd CA证书和CA证书的key
cfssl gencert -initca etcd-ca-csr.json | cfssljson -bare $ETCD_SSL_DIR/etcd-ca


cfssl gencert \
   -ca=$ETCD_SSL_DIR/etcd-ca.pem \
   -ca-key=$ETCD_SSL_DIR/etcd-ca-key.pem \
   -config=ca-config.json \
   -hostname=127.0.0.1,$ETH0_IP,etcd-master,k8s-master \
   -profile=kubernetes \
   etcd-csr.json | cfssljson -bare $ETCD_SSL_DIR/etcd



# Master01生成kubernetes证书
cd $CERT_BUILD_DIR

cfssl gencert -initca ca-csr.json | cfssljson -bare $K8S_PKI_DIR/ca


cfssl gencert   -ca=$K8S_PKI_DIR/ca.pem   -ca-key=$K8S_PKI_DIR/ca-key.pem   -config=ca-config.json   -hostname=10.96.0.1,$ETH0_IP,etcd-master,k8s-master,127.0.0.1,kubernetes,kubernetes.default,kubernetes.default.svc,kubernetes.default.svc.cluster,kubernetes.default.svc.cluster.local   -profile=kubernetes   apiserver-csr.json | cfssljson -bare $K8S_PKI_DIR/apiserver

cfssl gencert   -initca front-proxy-ca-csr.json | cfssljson -bare $K8S_PKI_DIR/front-proxy-ca 

cfssl gencert   -ca=$K8S_PKI_DIR/front-proxy-ca.pem   -ca-key=$K8S_PKI_DIR/front-proxy-ca-key.pem   -config=ca-config.json   -profile=kubernetes   front-proxy-client-csr.json | cfssljson -bare $K8S_PKI_DIR/front-proxy-client

# 生成controller-manage的证书
cfssl gencert \
   -ca=$K8S_PKI_DIR/ca.pem \
   -ca-key=$K8S_PKI_DIR/ca-key.pem \
   -config=ca-config.json \
   -profile=kubernetes \
   manager-csr.json | cfssljson -bare $K8S_PKI_DIR/controller-manager

# 注意，如果不是高可用集群，改为master01的地址，8443改为apiserver的端口，默认是6443
# set-cluster：设置一个集群项，

kubectl config set-cluster kubernetes \
     --certificate-authority=$K8S_PKI_DIR/ca.pem \
     --embed-certs=true \
     --server=https://$ETH0_IP:$K8S_API_PORT \
     --kubeconfig=$K8S_CONF_DIR/controller-manager.kubeconfig

# 设置一个环境项，一个上下文
kubectl config set-context system:kube-controller-manager@kubernetes \
    --cluster=kubernetes \
    --user=system:kube-controller-manager \
    --kubeconfig=$K8S_CONF_DIR/controller-manager.kubeconfig

# set-credentials 设置一个用户项

kubectl config set-credentials system:kube-controller-manager \
     --client-certificate=$K8S_PKI_DIR/controller-manager.pem \
     --client-key=$K8S_PKI_DIR/controller-manager-key.pem \
     --embed-certs=true \
     --kubeconfig=$K8S_CONF_DIR/controller-manager.kubeconfig


# 使用某个环境当做默认环境

kubectl config use-context system:kube-controller-manager@kubernetes \
     --kubeconfig=$K8S_CONF_DIR/controller-manager.kubeconfig



cfssl gencert \
   -ca=$K8S_PKI_DIR/ca.pem \
   -ca-key=$K8S_PKI_DIR/ca-key.pem \
   -config=ca-config.json \
   -profile=kubernetes \
   scheduler-csr.json | cfssljson -bare $K8S_PKI_DIR/scheduler

# 注意，如果不是高可用集群，改为master01的地址，8443改为apiserver的端口，默认是6443

kubectl config set-cluster kubernetes \
     --certificate-authority=$K8S_PKI_DIR/ca.pem \
     --embed-certs=true \
     --server=https://$ETH0_IP:$K8S_API_PORT \
     --kubeconfig=$K8S_CONF_DIR/scheduler.kubeconfig


kubectl config set-credentials system:kube-scheduler \
     --client-certificate=$K8S_PKI_DIR/scheduler.pem \
     --client-key=$K8S_PKI_DIR/scheduler-key.pem \
     --embed-certs=true \
     --kubeconfig=$K8S_CONF_DIR/scheduler.kubeconfig

kubectl config set-context system:kube-scheduler@kubernetes \
     --cluster=kubernetes \
     --user=system:kube-scheduler \
     --kubeconfig=$K8S_CONF_DIR/scheduler.kubeconfig


kubectl config use-context system:kube-scheduler@kubernetes \
     --kubeconfig=$K8S_CONF_DIR/scheduler.kubeconfig


cfssl gencert \
   -ca=$K8S_PKI_DIR/ca.pem \
   -ca-key=$K8S_PKI_DIR/ca-key.pem \
   -config=ca-config.json \
   -profile=kubernetes \
   admin-csr.json | cfssljson -bare $K8S_PKI_DIR/admin

# 注意，如果不是高可用集群，改为master01的地址，8443改为apiserver的端口，默认是6443

kubectl config set-cluster kubernetes     --certificate-authority=$K8S_PKI_DIR/ca.pem     --embed-certs=true     --server=https://$ETH0_IP:$K8S_API_PORT     --kubeconfig=$K8S_CONF_DIR/admin.kubeconfig
kubectl config set-credentials kubernetes-admin     --client-certificate=$K8S_PKI_DIR/admin.pem     --client-key=$K8S_PKI_DIR/admin-key.pem     --embed-certs=true     --kubeconfig=$K8S_CONF_DIR/admin.kubeconfig


kubectl config set-context kubernetes-admin@kubernetes     --cluster=kubernetes     --user=kubernetes-admin     --kubeconfig=$K8S_CONF_DIR/admin.kubeconfig


kubectl config use-context kubernetes-admin@kubernetes     --kubeconfig=$K8S_CONF_DIR/admin.kubeconfig
 
# 创建ServiceAccount Key  secret
openssl genrsa -out $K8S_PKI_DIR/sa.key 2048

openssl rsa -in $K8S_PKI_DIR/sa.key -pubout -out $K8S_PKI_DIR/sa.pub

