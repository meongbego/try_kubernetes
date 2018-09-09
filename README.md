# INSTALL KUBERNETES CENTOS 7
How to install Kubernetes

## Configure Host | Master And Node
Using your editor edit hosts
``` bash
sudo vi /etc/hosts
```
Add your node and master example
``` bash
192.168.1.1 kubemaster
192.168.1.2 kubenode
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain
```
## Disable Selinux | Master And Node
In this tutorial, we will not cover about SELinux configuration for Docker, so we will disable it.

``` bash
setenforce 0
sed -i --follow-symlinks 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux
```
## Enable br_net_filter Kernel Module | Master And Node
``` bash
modprobe br_netfilter
echo '1' > /proc/sys/net/bridge/bridge-nf-call-iptables
```
## Disable Swap | Master And Node
``` bash
swapoff -a
```
then comment your fstab example

``` bash
#/dev/mapper/centos_localhost--live-swap swap                    swap    defaults        0 0
```
## Install Docker | Master And Node
``` bash
yum install -y yum-utils device-mapper-persistent-data lvm2
```
Add the docker repository to the system and install docker-ce using the yum command.

``` bash
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum install -y docker-ce
```
## Install Kubernetes | Master And Node
Add the kubernetes repository to the centos 7 system by running the following command.
``` bash
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
        https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF
```
then

``` bash
yum install -y kubelet kubeadm kubectl
```
reboot your master and node
``` bash
reboot
```
Log in again to the server and start the services, docker and kubelet.

``` bash
systemctl start docker && systemctl enable docker
systemctl start kubelet && systemctl enable kubelet
```
## Change the cgroup-driver | Master And Node
``` bash
docker info | grep -i cgroup
```
And you see the docker is using 'cgroupfs' as a cgroup-driver.

Now run the command below to change the kuberetes cgroup-driver to 'cgroupfs'.

``` bash
sed -i 's/cgroup-driver=systemd/cgroup-driver=cgroupfs/g' /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
```
Now we're ready to configure the Kubernetes Cluster.

## Kubernetes Cluster Initialization | Master

``` bash
kubeadm init --apiserver-advertise-address=<master_ip> --pod-network-cidr=<your_cidr>
```
Note:

Copy the 'kubeadm join ... ... ...' command to your text editor. The command will be used to register new nodes to the kubernetes cluster.

Now in order to use Kubernetes, we need to run some commands as on the result.

Create new '.kube' configuration directory and copy the configuration 'admin.conf'.

``` bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

Next, deploy the flannel network to the kubernetes cluster using the kubectl command.

``` bash
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
```

Wait for a minute and then check kubernetes node and pods using commands below.

``` bash
kubectl get nodes
kubectl get pods --all-namespaces
```

## Adding Node to the Cluster | Node
You Rember in kubeadm join..... copy from your editor then exec from your nodes
example :

``` bash
kubeadm join 192.168.1.1:6443 --token vzau5v.vjiqyxq26lzsf28e --discovery-token-ca-cert-hash sha256:e6d046ba34ee03e7d55e1f5ac6d2de09fd6d7e6959d16782ef0778794b94c61e
```
Wait for some minutes and back to the 'k8s-master' master cluster server check the nodes and pods using the following command.

Check your node from master

``` bash
kubectl get nodes
kubectl get pods --all-namespaces
```


## Installing Dashboard
See Next Time

## How To Use BASH Excecution
You can execute the run.sh file

``` bash
sudo ./run.sh
```
Select the List of Functions that exist then execute each step from 1-11


## Testing Create First Pod | Master
In this step, we will do a test by deploying the Nginx pod to the kubernetes cluster. A pod is a group of one or more containers with shared storage and network that runs under Kubernetes. A Pod contains one or more containers, such as Docker container.

Login to the 'master' server and create new deployment named 'nginx' using the kubectl command.
``` bash
kubectl create deployment nginx --image=nginx
```
To see details of the 'nginx' deployment sepcification, run the following command.
``` bash
kubectl describe deployment nginx
```
And you will get the nginx pod deployment specification.

Next, we will expose the nginx pod accessible via the internet. And we need to create new service NodePort for this.

Run the kubectl command below.
``` bash
kubectl create service nodeport nginx --tcp=80:80
```
Make sure there is no error. Now check the nginx service nodeport and IP using the kubectl command below.

``` bash
kubectl get pods
kubectl get svc
```
from your master curl on port (remember port from your service | kubectl get svc)
``` bash
curl node:30691
```
then from your browser open url : node_ip:30691

