# Bootstrapping the etcd Cluster

Kubernetes components are stateless and store cluster state in [etcd](https://github.com/coreos/etcd). In this lab you will bootstrap a three node etcd cluster and configure it for high availability and secure remote access.

## Download etcd Binaries

Download the official etcd release binaries from the [coreos/etcd](https://github.com/coreos/etcd) GitHub project:

```
ETCD_VERSION=3.5.0
cd files/
wget -q --show-progress --https-only --timestamping \
  "https://github.com/coreos/etcd/releases/download/v${ETCD_VERSION}/etcd-v${ETCD_VERSION}-linux-amd64.tar.gz"
```
Downloaded file will appear in each VirtualBox machine, deployed with Vagrant. See `/vagrant` directory on each machine.
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


## Bootstrapping an etcd Cluster Member

### Install etcd Binaries
Extract and install the `etcd` server and the `etcdctl` command line utility:

```
ETCD_VERSION=3.5.0
tar -xvf /vagrant/files/etcd-v${ETCD_VERSION}-linux-amd64.tar.gz
```

```
sudo cp etcd-v${ETCD_VERSION}-linux-amd64/etcd* /usr/local/bin/
```

### Configure the etcd Server

```
sudo mkdir -p /etc/etcd /var/lib/etcd
```

```
(cd /vagrant/certs && sudo cp ca.pem kubernetes-key.pem kubernetes.pem /etc/etcd/)
```

The instance internal IP address will be used to serve client requests and communicate with etcd cluster peers. Retrieve the internal IP address for the current compute instance:

```
INTERNAL_IP=$(ip -4 --oneline addr | grep -v secondary | grep -oP '(10\.99\.13\.[0-9]{1,3})(?=/)')
```

Each etcd member must have a unique name within an etcd cluster. Set the etcd name to match the hostname of the current compute instance:

```
ETCD_NAME=$(hostname -s)
```

Create the `etcd.service` systemd unit file:

```
cat > etcd.service <<EOF
[Unit]
Description=etcd
Documentation=https://github.com/coreos

[Service]
ExecStart=/usr/local/bin/etcd \\
  --name ${ETCD_NAME} \\
  --cert-file=/etc/etcd/kubernetes.pem \\
  --key-file=/etc/etcd/kubernetes-key.pem \\
  --peer-cert-file=/etc/etcd/kubernetes.pem \\
  --peer-key-file=/etc/etcd/kubernetes-key.pem \\
  --trusted-ca-file=/etc/etcd/ca.pem \\
  --peer-trusted-ca-file=/etc/etcd/ca.pem \\
  --peer-client-cert-auth \\
  --client-cert-auth \\
  --initial-advertise-peer-urls https://${INTERNAL_IP}:2380 \\
  --listen-peer-urls https://${INTERNAL_IP}:2380 \\
  --listen-client-urls https://${INTERNAL_IP}:2379,http://127.0.0.1:2379 \\
  --advertise-client-urls https://${INTERNAL_IP}:2379 \\
  --initial-cluster-token etcd-cluster-0 \\
  --initial-cluster controller-0=https://10.99.13.10:2380,controller-1=https://10.99.13.11:2380,controller-2=https://10.99.13.12:2380 \\
  --initial-cluster-state new \\
  --data-dir=/var/lib/etcd
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
```

### Start the etcd Server

```
sudo mv etcd.service /etc/systemd/system/
```

```
sudo systemctl daemon-reload
```

```
sudo systemctl enable etcd
```

```
sudo systemctl start etcd
```

> Remember to run the above commands on each controller node: `controller-0`, `controller-1`, and `controller-2`.

## Verification

List the etcd cluster members:

```
ETCDCTL_API=3 etcdctl member list
```

> output

```
vagrant@controller-0:/etc/systemd/system$ ETCDCTL_API=3 etcdctl member list
1f9a55552b7bf63d, started, controller-1, https://10.99.13.11:2380, https://10.99.13.11:2379, false
76384c5b8ca8dd31, started, controller-2, https://10.99.13.12:2380, https://10.99.13.12:2379, false
d928e7fae18dd88d, started, controller-0, https://10.99.13.10:2380, https://10.99.13.10:2379, false
```

Next: [Bootstrapping the Kubernetes Control Plane](08-bootstrapping-kubernetes-controllers.md)
