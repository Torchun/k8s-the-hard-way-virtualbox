# Provisioning Compute Resources

Kubernetes requires a set of machines to host the Kubernetes control plane and the worker nodes where containers are ultimately run. In this lab you will provision the compute resources required for running a secure and highly available Kubernetes cluster.


## Networking

The Kubernetes [networking model](https://kubernetes.io/docs/concepts/cluster-administration/networking/#kubernetes-model) assumes a flat network in which containers and nodes can communicate with each other. In cases where this is not desired [network policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/) can limit how groups of containers are allowed to communicate with each other and external network endpoints.

Each machine uses two network interface, one for access the Internet with type "NAT", the other for Kubernetes internal communication with type "Host-only Adapter".


## Compute Instances

The compute instances in this lab will be provisioned using [Ubuntu Server](https://www.ubuntu.com/server) 20.04, which has good support for the [cri-containerd container runtime](https://github.com/kubernetes-incubator/cri-containerd). Each compute instance will be provisioned with a fixed private IP address to simplify the Kubernetes bootstrapping process.

## What's happening here

Take a look at config files:
* `Vagrantfile`
* `heartbeat.sh`

Kubernetes Virtual IP address configured via `/etc/ha.d/haresources` which is created with `heartbeat.sh`


### Start the VMs with Vagrant

`cd` to directory with `Vagrantfile`

```
vagrant up
```

> output

```
Bringing machine 'controller-0' up with 'virtualbox' provider...
Bringing machine 'controller-1' up with 'virtualbox' provider...
Bringing machine 'controller-2' up with 'virtualbox' provider...
Bringing machine 'worker-0' up with 'virtualbox' provider...
Bringing machine 'worker-1' up with 'virtualbox' provider...
Bringing machine 'worker-2' up with 'virtualbox' provider...
...
...

```

### Summary
List the compute instances:

```
vagrant status
```

> output
```
controller-0              running (virtualbox)
controller-1              running (virtualbox)
controller-2              running (virtualbox)
worker-0                  running (virtualbox)
worker-1                  running (virtualbox)
worker-2                  running (virtualbox)
```

## Kubernetes Master VIP
When Vagrant creates a virtual machine, it executes the deployment script `heartbeat.sh`, and uses heartbeat to configure VIPs on three controller nodes: 10.99.13.100. This IP is used for external access to Kubernetes.

### Verification
```
ping -c 1 10.99.13.100
```

> output

```
PING 10.99.13.100 (10.99.13.100): 56 data bytes
64 bytes from 10.99.13.100: icmp_seq=0 ttl=64 time=0.438 ms

--- 10.99.13.100 ping statistics ---
1 packets transmitted, 1 packets received, 0.0% packet loss
round-trip min/avg/max/stddev = 0.438/0.438/0.438/0.000 ms
```
If `ping` is not successfull, there is a problem with `heartbeat` service on nodes. Fastest way to fix is:
* shutdown all controllers
* start `controller-0` and `ssh` to it. 
* repeat start and `ssh` to each controller you have sequentially
* double-check with `ping` from laptop/desktop and `sudo service heartbeat status` on each controller


Next: [Provisioning a CA and Generating TLS Certificates](04-certificate-authority.md)
