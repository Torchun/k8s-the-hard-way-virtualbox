# Kubernetes The Hard Way

This is compilation of [Kelsey Hightower Labs](https://github.com/kelseyhightower) and [Eficode Praqma Labs](https://github.com/Praqma) for "Kubernetes The Hard Way".

Original GitHub repos can be found here:
* [https://github.com/sgargel/kubernetes-the-hard-way-virtualbox](https://github.com/sgargel/kubernetes-the-hard-way-virtualbox)
* [https://github.com/Praqma/LearnKubernetes/blob/master/kamran/Kubernetes-The-Hard-Way-on-BareMetal.md](https://github.com/Praqma/LearnKubernetes/blob/master/kamran/Kubernetes-The-Hard-Way-on-BareMetal.md)

The original guide is now dated and following it step by step produces some errors. This is an attempt to update it, but it is a WorkInProgress... a project to pass the time during the #covid19 #lockdown

> "Kubernetes The Hard Way" is a wonderful tutorial for setting up Kubernetes step by step. But [Google Cloud Platform](https://cloud.google.com/) is somehow not convenient for me, so I use VirtualBox to provision compute resources. The major differences between GCP and VirtualBox come with the networking, and could be fixed easily. Everything else keeps the same with origin.

This tutorial walks you through setting up Kubernetes the hard way. This guide is not for people looking for a fully automated command to bring up a Kubernetes cluster. If that's you then check out [Google Container Engine](https://cloud.google.com/container-engine), or the [Getting Started Guides](http://kubernetes.io/docs/getting-started-guides/).

Kubernetes The Hard Way is optimized for learning, which means taking the long route to ensure you understand each task required to bootstrap a Kubernetes cluster.

> The results of this tutorial should not be viewed as production ready, and may receive limited support from the community, but don't let that stop you from learning!

## Target Audience

The target audience for this tutorial is someone planning to support a production Kubernetes cluster and wants to understand how everything fits together.

## Cluster Details

Kubernetes The Hard Way guides you through bootstrapping a highly available Kubernetes cluster with end-to-end encryption between components and RBAC authentication.

* [Kubernetes](https://github.com/kubernetes/kubernetes) 1.21.0
* [containerd Container Runtime](https://github.com/containerd/containerd) 1.3.3
* [CNI Container Networking](https://github.com/containernetworking/cni) 0.7.1
* [etcd](https://github.com/coreos/etcd) 3.4.7

## Labs

This tutorial assumes you have VirtualBox installed. While VirtualBox is used for basic infrastructure requirements the lessons learned in this tutorial can be applied to other platforms. All actions expected to be performed at project's directory containing `Vagrantfile` and scripts. This directory considered as "home" for Labs by default. Keep an eye on this!

* [Prerequisites](docs/01-prerequisites.md)
* [Installing the Client Tools](docs/02-client-tools.md)
* [Provisioning Compute Resources](docs/03-compute-resources.md)
* [Provisioning the CA and Generating TLS Certificates](docs/04-certificate-authority.md)
* [Generating Kubernetes Configuration Files for Authentication](docs/05-kubernetes-configuration-files.md)
* [Generating the Data Encryption Config and Key](docs/06-data-encryption-keys.md)
* [Bootstrapping the etcd Cluster](docs/07-bootstrapping-etcd.md)
* [Bootstrapping the Kubernetes Control Plane](docs/08-bootstrapping-kubernetes-controllers.md)
* [Bootstrapping the Kubernetes Worker Nodes](docs/09-bootstrapping-kubernetes-workers.md)
* [Configuring kubectl for Remote Access](docs/10-configuring-kubectl.md)
* [Provisioning Pod Network Routes](docs/11-pod-network-routes.md)
* [Deploying the DNS Cluster Add-on](docs/12-dns-addon.md)
* [Smoke Test](docs/13-smoke-test.md)
* [Cleaning Up](docs/14-cleanup.md)
