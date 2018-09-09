function check_inet(){
    if ping -q -c 1 -W 1 8.8.8.8 >/dev/null; then
        echo "Connecting | Download Data"
    else
        echo "You Must Connect Internet"
        exit
    fi
}

function check_root(){
    if (( $EUID != 0 )); then
        echo "Please run as root"
        exit
    fi

}

function configure_host(){
    echo "Step 1 : Configure Your Host"
    read -p "Master Size : " master_size
    read -p "Node Size : " node_size

    counter=1
    while [ $counter -le $master_size ]
    do
        read -p "IP Address Master $counter :" ip_address_master
        read -p "Hostname Master $counter :" hostname_master
        # echo "$ip_address_master    $hostname_master" >> /etc/hosts
        echo "$ip_address_master    $hostname_master" >> test
        ((counter++))
    done

    counter=1
    while [ $counter -le $node_size ]
    do
        read -p "IP Address Node $counter :" ip_address_node
        read -p "Hostname Node $counter :" hostname_node
        echo "$ip_address_node    $hostname_node" >> test
        # echo "$ip_address_node    $hostname_node" >> /etc/hosts
        ((counter++))
    done
}

function disable_selinux(){
    echo "2. Disable Selinux"
    setenforce 0
    sed -i --follow-symlinks 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux
}

function disable_swap(){
    echo "3. Disable Swap Memory"
    swapoff -a
    echo "Permanently configuration must edit your fstab and comment your swap uuid"
}

function install_docker(){
    echo "4. Installing Docker CE"
    check_inet
    # yum install -y yum-utils device-mapper-persistent-data lvm2
    echo "Add the docker repository to the system and install docker-ce using the yum command"
    yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    echo "Instal Docker CE"
    yum install -y docker-ce
}

function install_kubernetes(){
    check_inet
    echo "5. Installing Kubernetes"
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
    yum install -y kubelet kubeadm kubectl
}

function exec_startup(){
    echo "6. Execute Start Up Docker And Kubernetes"
    systemctl start docker && systemctl enable docker
    systemctl start kubelet && systemctl enable kubelet
}

function cg_group(){
    echo "7. Configure cg_group"
    docker info | grep -i cgroup
    sed -i 's/cgroup-driver=systemd/cgroup-driver=cgroupfs/g' /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
}

function kube_exec(){
    echo "8. Get Kubeadmin Token"
    read -p "Enter Your Master IP : " ip_master
    read -p "Enter Your Master CIDR : " cidr_master
    kubeadm init --apiserver-advertise-address=$ip_master --pod-network-cidr=$cidr_master > kubeadm.txt
    echo "Checking file kubeadm.txt result this command to add node future"

}

function create_kube_config(){
    echo "9. Create Kube Configuration"
    mkdir -p $HOME/.kube
    cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    chown $(id -u):$(id -g) $HOME/.kube/config
}

function create_flannel_net(){
    echo "10. Create Flanel Network"
    check_inet
    kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
    echo "Wait for a minute and then check kubernetes node and pods using commands below."
}

function check_node(){
    echo "11. Checking Node"
    kubectl get nodes
    kubectl get pods --all-namespaces
}



##----------------- main programming ---------------------##
echo "#------------------------------------------------------------------#"
echo "#         Welcome This Script Installing Kubernetes                #"
echo "#------------------------------------------------------------------#"
check_root
while true; do 
    echo "1. Configure Host | Master And Node"
    echo "2. Disable Selinux | Master And Node"
    echo "3. Disable Swap | Master And Node"
    echo "4. Installing Docker CE | Master And Node"
    echo "5. Installing Kubernetes | Master And Node"
    echo "6. Execute Start Up Docker And Kubernetes | Master And Node"
    echo "7. Configure cg_group | Master And Node"
    echo "8. Get Kubeadmin Token | Master"
    echo "9. Create Kube Configuration | Master"
    echo "10. Create Flanel Network | Master"
    echo "11. Checking Node | Master"
    echo "12. Add Node | Node (Deployment)"
    echo "0. Exit"
    read -p "Choose One Function : " choose

    if (($choose == 1));
        then
        configure_host
        report="Configure Host Success"
    elif (( $choose == 2 ));
        then
        disable_selinux
    elif (( $choose == 3 ));
        then
        disable_swap
        report="Disabled Swap Success"
    elif (( $choose == 4 ));
        then
        install_docker
        report="Install Docker Success"
    elif (( $choose == 5 ));
        then
        install_kubernetes
        report="Install Kubernetes Success"
    elif (( $choose == 6 ));
        then
        exec_startup
        report="Docker And Kubernetes Set To Startup Mode"
    elif (( $choose == 7 ));
        then
        cg_group
        report="Cg Group Success Change"
    elif (( $choose == 8 ));
        then
        kube_exec
        report="Kubeadmin Token Success Build"
    elif (( $choose == 9 ));
        then
        create_kube_config
        report="Kube Configuration Created"
    elif (( $choose == 10 ));
        then
        create_flannel_net
        report="Flannel Net Created"
    elif (( $choose == 11 ));
        then
        check_node
    elif (( $choose == 12 ));
        then
        report="This Function Deployment Mode"
    elif (( $choose == 0 ));
        then
        echo "Thank You See You Next Time"
        break
    else
        echo "Select Function In List"
    fi

    echo $report
    sleep 2
    clear
done

