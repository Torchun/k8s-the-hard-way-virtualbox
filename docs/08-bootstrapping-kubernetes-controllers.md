# Bootstrapping the Kubernetes Control Plane

In this lab you will bootstrap the Kubernetes control plane across three compute instances and configure it for high availability. The following components will be installed on each node: Kubernetes API Server, Scheduler, and Controller Manager.

Will be also configured `kubectl` inside controller nodes.

Execute on local laptop/desktop

Go to `certs/` directory and execute:

```
cat > controller-kubectl-config.yaml <<EOF
apiVersion: v1
clusters:
- cluster:
    server: http://127.0.0.1:8080
  name: kubernetes-the-hard-way
contexts:
- context:
    cluster: kubernetes-the-hard-way
    user: admin
  name: kubernetes-the-hard-way
current-context: kubernetes-the-hard-way
kind: Config
preferences: {}
EOF
```

Result is:

```
controller-kubectl-config.yaml
```

## Download the Kubernetes Controller Binaries

Download the official Kubernetes release binaries into `files` directory:

```
wget -q --show-progress --https-only --timestamping \
  "https://storage.googleapis.com/kubernetes-release/release/v1.21.0/bin/linux/amd64/kube-apiserver" \
  "https://storage.googleapis.com/kubernetes-release/release/v1.21.0/bin/linux/amd64/kube-controller-manager" \
  "https://storage.googleapis.com/kubernetes-release/release/v1.21.0/bin/linux/amd64/kube-scheduler" \
  "https://storage.googleapis.com/kubernetes-release/release/v1.21.0/bin/linux/amd64/kubectl"
```
That files will appear in each of deployed by  Vagrant instances, see `/vagrant` directory
## Prerequisites

The commands in this lab must be run on each controller instance: `controller-0`, `controller-1`, and `controller-2`. Login to each controller instance using the `vagrant ssh` command.

Tmux can be used on local laptop/desktop to perform described action simultaneously:
```
tmux
```
* hit `Ctrl+b` `%` twice - it will split window into 3 columns
* `Ctrl+b` `Alt+2` will switch to horizontal split with equal spacing
* `Ctrl+b` `Alt+1` do the same but vertically
* `Ctrl+b` `→` to change active split to right or `Ctrl+b` `←` to move left
* `Ctrl+b` `:` and type `resize-pane -D 10` to move current pane lower border down to 10 lines
* `Ctrl+b` `:` and type `resize-pane -U 10` to move current pane lower border up to 10 lines

On each window establish new connection to corresponding `controller-X`

```
vagrant ssh controller-0
vagrant ssh controller-1
vagrant ssh controller-2
```
When conections established, configure Tmux for panes syncronization:
* `Ctrl+b` `:` and type `setw synchronize-panes on`
* go to preferred pane and check sync is working correctly: `hostname`
* on controllers, `cd /vagrant/files`

## Provision the Kubernetes Control Plane

### Configure kubectl
Configure kubectl:

```
(mkdir -p ~/.kube/ && cp /vagrant/certs/controller-kubectl-config.yaml ~/.kube/config)
```

### Install the Kubernetes Controller Binaries
Install the Kubernetes binaries:

```
(cd /vagrant/files && sudo cp kube-apiserver kube-controller-manager kube-scheduler kubectl /usr/local/bin/)
```

```
(cd /usr/local/bin && sudo chmod +x kube-apiserver kube-controller-manager kube-scheduler kubectl)
```

### Configure the Kubernetes API Server

```
sudo mkdir -p /var/lib/kubernetes/
```

```
(cd /vagrant/certs && sudo cp ca.pem ca-key.pem kubernetes-tls-cert-file.pem kubernetes-key.pem kubernetes.pem encryption-config.yaml /var/lib/kubernetes/)
```

The instance internal IP address will be used advertise the API Server to members of the cluster. Retrieve the internal IP address for the current compute instance:

```
INTERNAL_IP=$(ip -4 --oneline addr | grep -v secondary | grep -oP '(10\.99\.13\.[0-9]{1,3})(?=/)')
```

Create the `kube-apiserver.service` systemd unit file:

```
cat > kube-apiserver.service <<EOF
[Unit]
Description=Kubernetes API Server
Documentation=https://github.com/GoogleCloudPlatform/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-apiserver \\
  --enable-admission-plugins=NamespaceLifecycle,NodeRestriction,LimitRanger,ServiceAccount,DefaultStorageClass,ResourceQuota \\
  --advertise-address=${INTERNAL_IP} \\
  --allow-privileged=true \\
  --apiserver-count=3 \\
  --audit-log-maxage=30 \\
  --audit-log-maxbackup=3 \\
  --audit-log-maxsize=100 \\
  --audit-log-path=/var/log/audit.log \\
  --authorization-mode=Node,RBAC \\
  --bind-address=0.0.0.0 \\
  --client-ca-file=/var/lib/kubernetes/ca.pem \\
  --enable-swagger-ui=true \\
  --etcd-cafile=/var/lib/kubernetes/ca.pem \\
  --etcd-certfile=/var/lib/kubernetes/kubernetes.pem \\
  --etcd-keyfile=/var/lib/kubernetes/kubernetes-key.pem \\
  --etcd-servers=https://10.99.13.10:2379,https://10.99.13.11:2379,https://10.99.13.12:2379 \\
  --event-ttl=1h \\
  --encryption-provider-config=/var/lib/kubernetes/encryption-config.yaml \\
  --insecure-bind-address=127.0.0.1 \\
  --insecure-port=8080 \\
  --kubelet-certificate-authority=/var/lib/kubernetes/ca.pem \\
  --kubelet-client-certificate=/var/lib/kubernetes/kubernetes.pem \\
  --kubelet-client-key=/var/lib/kubernetes/kubernetes-key.pem \\
  --kubelet-https=true \\
  --runtime-config=api/all=true \\
  --service-account-key-file=/var/lib/kubernetes/ca-key.pem \\
  --service-cluster-ip-range=10.32.0.0/24 \\
  --service-node-port-range=30000-32767 \\
  --tls-cert-file=/var/lib/kubernetes/kubernetes-tls-cert-file.pem \\
  --tls-private-key-file=/var/lib/kubernetes/kubernetes-key.pem \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
```

### Configure the Kubernetes Controller Manager

Create the `kube-controller-manager.service` systemd unit file:

```
cat > kube-controller-manager.service <<EOF
[Unit]
Description=Kubernetes Controller Manager
Documentation=https://github.com/GoogleCloudPlatform/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-controller-manager \\
  --address=0.0.0.0 \\
  --allocate-node-cidrs=true \\
  --cluster-cidr=10.244.0.0/16 \\
  --cluster-name=kubernetes \\
  --cluster-signing-cert-file=/var/lib/kubernetes/ca.pem \\
  --cluster-signing-key-file=/var/lib/kubernetes/ca-key.pem \\
  --leader-elect=true \\
  --master=http://127.0.0.1:8080 \\
  --root-ca-file=/var/lib/kubernetes/ca.pem \\
  --service-account-private-key-file=/var/lib/kubernetes/ca-key.pem \\
  --service-cluster-ip-range=10.32.0.0/24 \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
```

### Configure the Kubernetes Scheduler

Create the `kube-scheduler.service` systemd unit file:

```
cat > kube-scheduler.service <<EOF
[Unit]
Description=Kubernetes Scheduler
Documentation=https://github.com/GoogleCloudPlatform/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-scheduler \\
  --leader-elect=true \\
  --master=http://127.0.0.1:8080 \\
  --v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
```

### Start the Controller Services

```
sudo mv kube-apiserver.service kube-scheduler.service kube-controller-manager.service /etc/systemd/system/
```

```
sudo systemctl daemon-reload
```

```
sudo systemctl enable kube-apiserver kube-controller-manager kube-scheduler
```

```
sudo systemctl start kube-apiserver kube-controller-manager kube-scheduler
```

> Allow up to 10 seconds for the Kubernetes API Server to fully initialize.

### Verification

To execute commands below is necessary to have previuosly configured `kubeadm` on controllers node or an error will be shown: `error: no configuration has been provided, try setting KUBERNETES_MASTER environment variable`

```
kubectl get componentstatuses
```

```
NAME                 STATUS    MESSAGE              ERROR
controller-manager   Healthy   ok
scheduler            Healthy   ok
etcd-2               Healthy   {"health": "true"}
etcd-0               Healthy   {"health": "true"}
etcd-1               Healthy   {"health": "true"}
```

> Remember to run the above commands on each controller node: `controller-0`, `controller-1`, and `controller-2`.

## RBAC for Kubelet Authorization

In this section you will configure RBAC permissions to allow the Kubernetes API Server to access the Kubelet API on each worker node. Access to the Kubelet API is required for retrieving metrics, logs, and executing commands in pods.

> This tutorial sets the Kubelet `--authorization-mode` flag to `Webhook`. Webhook mode uses the [SubjectAccessReview](https://kubernetes.io/docs/admin/authorization/#checking-api-access) API to determine authorization.


```
vagrant ssh controller-0
```

Create the `system:kube-apiserver-to-kubelet` [ClusterRole](https://kubernetes.io/docs/admin/authorization/rbac/#role-and-clusterrole) with permissions to access the Kubelet API and perform most common tasks associated with managing pods:

```
cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRole
metadata:
  annotations:
    rbac.authorization.kubernetes.io/autoupdate: "true"
  labels:
    kubernetes.io/bootstrapping: rbac-defaults
  name: system:kube-apiserver-to-kubelet
rules:
  - apiGroups:
      - ""
    resources:
      - nodes/proxy
      - nodes/stats
      - nodes/log
      - nodes/spec
      - nodes/metrics
    verbs:
      - "*"
EOF
```

The Kubernetes API Server authenticates to the Kubelet as the `kubernetes` user using the client certificate as defined by the `--kubelet-client-certificate` flag.

Bind the `system:kube-apiserver-to-kubelet` ClusterRole to the `kubernetes` user:

```
cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: system:kube-apiserver
  namespace: ""
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:kube-apiserver-to-kubelet
subjects:
  - apiGroup: rbac.authorization.k8s.io
    kind: User
    name: kubernetes
EOF
```

## Verification VIP

Retrieve the `kubernetes-the-hard-way` static IP address:

```
KUBERNETES_PUBLIC_ADDRESS="192.168.100.100"
```

Make a HTTP request for the Kubernetes version info:

```
curl --cacert ca.pem https://${KUBERNETES_PUBLIC_ADDRESS}:6443/version
```

> output

```
{
  "major": "1",
  "minor": "8",
  "gitVersion": "v1.8.0",
  "gitCommit": "6e937839ac04a38cac63e6a7a306c5d035fe7b0a",
  "gitTreeState": "clean",
  "buildDate": "2017-09-28T22:46:41Z",
  "goVersion": "go1.8.3",
  "compiler": "gc",
  "platform": "linux/amd64"
```

Next: [Bootstrapping the Kubernetes Worker Nodes](09-bootstrapping-kubernetes-workers.md)
