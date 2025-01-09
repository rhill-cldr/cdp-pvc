# Setup

## Partners Program | Requesting a License Key

Sign up using a "technical" role to expidite license approval.

-- https://www.cloudera.com/partners.html

## Configure your local license info

1. Copy your CDP license and paywall credentials to `~/.cloudera/` and rename to `license.txt` and `info.txt` respectively:
  ```
  mkdir ~/.cloudera
  cp /path/to/files/* ~/.cloudera/
  cd ~/.cloudera/
  mv <your_filename>_license.txt license.txt
  mv <your_filename>_info.txt info.txt
  ```
2. Copy your paywall credentials into environment vars in `~/.cloudera/info.sh`:
  ```
  export CLOUDERA_USERNAME=<login value from info.txt>
  export CLOUDERA_PASSWORD=<password value from info.txt>
  ```


## Install Nixpkgs
Use the method of your choice, e.g.:
- https://github.com/DeterminateSystems/nix-installer
- https://nixos.org/download.html#download-nix

## Install Direnv | Homebrew or Nixpkgs
-- https://direnv.net/

### 1. MacOS Homebrew

`brew install direnv`

-- https://formulae.brew.sh/formula/direnv#default

### 2. Nixpkgs Home-Manager

Add to e.g. `~/.config/nixpkgs/home.nix`:
```nix
{ config, pkgs, ... }:

{
  home = {
  # ...
    programs = {
      direnv = {
        enable = true;
        nix-direnv.enable = true;
        config = {
          load_dotenv = true;
        };
      };
    };
  # ...
  };
}
```


### Configure Direnv

#### BASH
Add the following line at the end of the ~/.bashrc file:

`eval "$(direnv hook bash)"`

Make sure it appears even after rvm, git-prompt and other shell extensions that manipulate the prompt.

#### ZSH
Add the following line at the end of the ~/.zshrc file:

`eval "$(direnv hook zsh)"`

Open a new terminal or `source` the appropriate files.

### Load the local environment

```
direnv allow .
```

### Root Key

TODO: location

```
ssh-keygen -t rsa -b 4096 -f root_key
```

## Provision Machines

### 1. Select your cluster profile

From the project root:

```
cd src/main/opentf
ll
total 8.0K
    .
    ..
    env.conf
    equinix_lg
    equinix_md
    equinix_sm
    info.sh
``` 

Select a cluster profile, e.g:

```
cd equinix_md
terraform init
terraform plan -out tf.plan
terraform apply tf.plan 
```

## Project Setup

1. Confirm the location of the CDP license and root_key in `.envrc`, e.g.:
  ```
  export YCLOUD_ROOT_KEY=$HOME/.ssh/root_key
  export CLOUDERA_MANAGER_LICENSE_FILE=$HOME/.cloudera/license.txt
  ```

2. Override values in `.env` as necessary:
  ```
  #export YCLOUD_SHORT_NAME=<custom value>-dev
  #export REALM_PREFIX=<CUSTOM VALUE>-DEV
  #export IPA_SERVER_HOST=<prefix>.<custom_value>-<custom_domain>
  #export CM_URL=https://<prefix>.<custom_value>-<custom_domain>:7183
  # Also set these values in:
  # - runner/project/files/setup-ipa.sh
  # - runner/project/files/cmca.json
  ```

3. Reload the local environment:
  ```
  direnv allow .
  ```


## Configure Cloudera Manager

1. Confirm the target cluster inventory:
  ```
  pyhocon -i runner/inventory/hosts.conf -f json
  ```

2. Execute `ansible-runner` via the included Nix script. 
  ```
  nix run .
  ```
  
  If you encounter a `UNREACHABLE!` error, first confirm connectivity with the target machines:
  ```
  ansible-runner run runner -p ping.yml
  ```
  
  If the error includes:
  ```
  Permission denied (publickey,gssapi-keyex,gssapi-with-mic,password,keyboard-interactive).
  ```
  
  Then connect to at least the first host and edit `ChallengeResponseAuthentication` in `/etc/ssh/sshd_config` to match the following:
  ```
  # Change to no to disable s/key passwords
  ChallengeResponseAuthentication yes
  #ChallengeResponseAuthentication no
  ```
  
3. Access Cloudera Manager, optionally enable Kerberos, and create a base cluster.
  ```
  open $CM_URL
  ```

NOTE: To enable Kerboeros, accept the provided configuration values, and enter `admin` and `Super@Secret1` (or $THE_PWD value) to authenticate.

## Apache Airflow

export AIRFLOW_CONSTRAINTS=https://raw.githubusercontent.com/apache/airflow/constraints-${CDP_AIRFLOW_VERSION}/constraints-${RHEL8_PYTHON39_VERSION}.txt

dnf install gcc-c++ python39-devel cyrus-sasl-devel -y
python39 -m pip install --upgrade pip setuptools wheel

## Spark 3

Assuming:
- Nixpkgs is installed locally
- Direnv is convigured for Nix
- A cluster has beed deployed like [detroit.json](./runner/project/files/detroit.json)

```
cd ~/local/src
nix-shell -p sbt --run "sbt new rch/sbt-nix.g8"
cd demo     # or the name of the project entered in the previous command
echo 'use nix' >> .envrc
direnv allow .
sbt package
scp -i ~/.ssh/root_key target/scala-2.12/sbt-nix-demo_2.12-0.1.0-SNAPSHOT.jar root@<base_cluster_url>:demo.jar
ssh -i ~/.ssh/root_key root@ccycloud-4.$USER-dev.root.hwx.site 
kinit admin@ < your ycloud short name> .ROOT.HWX.SITE
spark3-submit --class cloudera.demo.Hello  --master yarn --deploy-mode cluster --executor-memory 1g demo.jar
```


# Kubernetes | Embedded Container Service (ECS)

## Wildcard DNS

|   |   |   |
|---|---|---|
|CNAME|*.app.dev.metal|dev.metal.zndx.org|

## Cleanup

- https://docs.cloudera.com/cdp-private-cloud-data-services/latest/installation-ecs/topics/cdppvc-installation-ecs-uninstall-pvc.html
- https://jira.cloudera.com/browse/DOCS-13479

```
# Before stopping or deleting ECS

/opt/cloudera/parcels/ECS/docker/docker container stop registry
/opt/cloudera/parcels/ECS/docker/docker container rm -v registry
/opt/cloudera/parcels/ECS/docker/docker image rm registry:2

# Stop the ECS cluster

cd /opt/cloudera/parcels/ECS/bin
./rke2-killall.sh && ./rke2-killall.sh 
./rke2-uninstall.sh
docker_store='/mnt/volume1/docker*'
local_store='/mnt/volume1/ecs/local-storage*'
longhorn_store='/mnt/volume1/ecs/longhorn-storage*'

sudo rm -rf /mnt/volume1/docker*
sudo rm -rf /mnt/volume1/ecs/local-storage*
sudo rm -rf /mnt/volume1/ecs/longhorn-storage*
rm -rf /var/lib/docker_server/* 
rm -rf /etc/docker/certs.d/* 
rm -rf /var/lib/rancher/*

# Delete the ECS cluster
```


## Packages

```
dnf install -y java-11-openjdk-devel python38 iptables python38-psycopg2 postgresql-jdbc nfs-utils nmap chrony sshpass 
```


## NetworkManager[​](https://docs.rke2.io/known_issues/#networkmanager "Direct link to NetworkManager")

- https://docs.rke2.io/known_issues/#networkmanager

NetworkManager manipulates the routing table for interfaces in the default network namespace where many CNIs, including RKE2's default, create veth pairs for connections to containers. This can interfere with the CNI’s ability to route correctly. As such, if installing RKE2 on a NetworkManager enabled system, it is highly recommended to configure NetworkManager to ignore calico/flannel related network interfaces. In order to do this, create a configuration file called `rke2-canal.conf` in `/etc/NetworkManager/conf.d` with the contents:

```
vi /etc/NetworkManager/conf.d/rke2-canal.conf
```

```
[keyfile]
unmanaged-devices=interface-name:cali*;interface-name:flannel*
```

```
# RHEL 8.4
systemctl disable nm-cloud-setup.service nm-cloud-setup.timer
```

## Disable THP



```
Transparent Huge Page Compaction is enabled and can cause significant performance problems. Run "echo never > /sys/kernel/mm/transparent_hugepage/defrag" and "echo never > /sys/kernel/mm/transparent_hugepage/enabled" to disable this, and then add the same command to an init script such as /etc/rc.local so it will be set on system reboot. The following hosts are affected:
```

```
vi /etc/rc.local

echo never > /sys/kernel/mm/transparent_hugepage/defrag
echo never > /sys/kernel/mm/transparent_hugepage/enabled
```

```
#
# It is highly advisable to create own systemd services or udev rules
# to run scripts during boot instead of using this file.
#
```



## DNS


-- https://developers.cloudflare.com/1.1.1.1/setup/linux/


### Use command line interface (CLI)

Choose whether you want to use 1.1.1.1 or 1.1.1.1 For Families, and replace `1.1.1.1` with the corresponding [IPv4 or IPv6 address](https://developers.cloudflare.com/1.1.1.1/ip-addresses/) accordingly.

#### [​​](https://developers.cloudflare.com/1.1.1.1/setup/linux/#resolvconf)`resolv.conf`

Usually, `/etc/resolv.conf` is where you can configure the resolver IPs that your system is using.

In that case, you can use the following one-line command to specify `1.1.1.1` as your DNS resolver and `1.0.0.1` as backup:

```
echo -e "search dev.metal.zndx.org\nnameserver 1.1.1.1\nnameserver 1.0.0.1\nnameserver 147.75.207.207\nnameserver 147.75.207.208" | sudo tee /etc/resolv.conf
```

```
search dev.metal.zndx.org
nameserver 1.1.1.1
nameserver 1.0.0.1
nameserver 147.75.207.207
nameserver 147.75.207.208
```

```
dig ecs-worker-01.dev.metal.zndx.org
dig ecs-worker-02.dev.metal.zndx.org
dig ecs-worker-03.dev.metal.zndx.org
dig ecs-worker-04.dev.metal.zndx.org
dig ecs-worker-05.dev.metal.zndx.org
```

## Auth

```
echo 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC5Zx7QmkQF+YIYxZ3z7KeD/CJAkzijm49QHQDIA0AnY2rLqFj09ZvKKFPVh+wnEU4PhKMVAGlBBjlItumxwx90BTstgnQqXK09GR4KBQAq2vpwUz4prkllj84wMrBlIAWcWXSJxO5zI4atcIDBnUw+W0dfgjMzgKAfnrg45xT+rMzQw41t1rtcURO3VgmvDHt1xAAZ/Zo5XjguOhIhdR9IOyTwyowHHcm2IGeuLuOeupAhcQc+7tEX+Jj8fxs9+0tbV4HYG3kM1Xe2r4kq5OPtM4YVOHRvqwmjmClR+i21iAs3EUWVRHI1KYywrULak7u01Y6PnI3pJ7pcO4HchgSR' >> ~/.ssh/authorized_keys
```


## Warp Agent + CF DNS


## Drives

A minimum of 300 GiB of storage is required in the /var/lib directory
300 GiB in the configured docker data directory

```
lshw -short
```

## ECS Masters

/dev/sda   disk           480GB MZ7LH480HBHQ0D3
/dev/sdb   disk           480GB MZ7LH480HBHQ0D3
 
```
lsblk -f /dev/sdc
lsblk -f /dev/sdd

mkfs.ext4 /dev/sdc
mkfs.ext4 /dev/sdd

mkdir -p /mnt/volume1
mkdir -p /mnt/volume2

mount -o defaults /dev/sdc /mnt/volume1
mount -o defaults /dev/sdd /mnt/volume2
```

```
lsblk
NAME   MAJ:MIN RM   SIZE RO TYPE MOUNTPOINT
sda      8:0    0 447.1G  0 disk /mnt/volume1
sdb      8:16   0 447.1G  0 disk /mnt/volume2
sdc      8:32   0 223.6G  0 disk
├─sdc1   8:33   0     2M  0 part
├─sdc2   8:34   0   1.9G  0 part [SWAP]
└─sdc3   8:35   0 221.7G  0 part /
sdd      8:48   0 223.6G  0 disk
```


```
mkdir -p /mnt/volume1/var/lib
rsync -av /var/lib/ /mnt/volume1/var/lib/
ls -l /mnt/volume1/var/lib/
mv /var/lib /var/lib_backup
mkdir /var/lib
mount --bind /mnt/volume1/var/lib /var/lib
```

### Master-01

```
[root@ecs-master-01 ~]# blkid /dev/sdc
/dev/sdc: UUID="78942997-3917-4c55-ad87-2544ef5312f9" BLOCK_SIZE="4096" TYPE="ext4"
[root@ecs-master-01 ~]# blkid /dev/sdd
/dev/sdd: UUID="339c0433-8076-463f-9408-6a12eda5e72c" BLOCK_SIZE="4096" TYPE="ext4"

# vi fstab
UUID=78942997-3917-4c55-ad87-2544ef5312f9  /mnt/volume1  ext4  defaults  0 2
UUID=339c0433-8076-463f-9408-6a12eda5e72c  /mnt/volume2  ext4  defaults  0 2
/mnt/volume1/var/lib /var/lib none bind 0 0

mount -a
```

### Master-02

```
lsblk
NAME   MAJ:MIN RM   SIZE RO TYPE MOUNTPOINT
sda      8:0    0 223.6G  0 disk
├─sda1   8:1    0     2M  0 part
├─sda2   8:2    0   1.9G  0 part [SWAP]
└─sda3   8:3    0 221.7G  0 part /
sdb      8:16   0 223.6G  0 disk
sdc      8:32   0 447.1G  0 disk
sdd      8:48   0 447.1G  0 disk
```

```
lsblk -f /dev/sda
lsblk -f /dev/sdb

mkfs.ext4 /dev/sda
mkfs.ext4 /dev/sdb

mkdir -p /mnt/volume1
mkdir -p /mnt/volume2

mount -o defaults /dev/sda /mnt/volume1
mount -o defaults /dev/sdb /mnt/volume2
```


```
[root@ecs-master-02 ~]# blkid /dev/sda
/dev/sda: UUID="47641953-e906-4f4a-89ff-59b9d5814821" BLOCK_SIZE="4096" TYPE="ext4"
[root@ecs-master-02 ~]# blkid /dev/sdb
/dev/sdb: UUID="f6f8af03-90e5-4147-b34a-39f4d11b3eaa" BLOCK_SIZE="4096" TYPE="ext4"


# vi fstab
UUID=47641953-e906-4f4a-89ff-59b9d5814821  /mnt/volume1  ext4  defaults  0 2
UUID=f6f8af03-90e5-4147-b34a-39f4d11b3eaa  /mnt/volume2  ext4  defaults  0 2
/mnt/volume1/var/lib /var/lib none bind 0 0

mount -a
```



## ECS Workers

```
lshw -short |grep -E '3840GB NVMe disk'
/0/101/2/0/1     /dev/nvme2n1    disk           3840GB NVMe disk
/0/101/3/0/1     /dev/nvme3n1    disk           3840GB NVMe disk
```

```
mkfs.ext4 /dev/nvme2n1
mkdir -p /mnt/volume1
mount -o defaults /dev/nvme2n1 /mnt/volume1

mkfs.ext4 /dev/nvme3n1
mkdir -p /mnt/volume2
mount -o defaults /dev/nvme3n1 /mnt/volume2
```

```
lsblk
NAME        MAJ:MIN RM   SIZE RO TYPE MOUNTPOINT
nvme0n1     259:0    0 238.5G  0 disk
├─nvme0n1p1 259:1    0   512M  0 part /boot/efi
├─nvme0n1p2 259:2    0   1.9G  0 part [SWAP]
└─nvme0n1p3 259:3    0 236.1G  0 part /
nvme1n1     259:4    0 238.5G  0 disk
nvme2n1     259:5    0   3.5T  0 disk /mnt/volume1
nvme3n1     259:6    0   3.5T  0 disk /mnt/volume2
```


```
mkdir -p /mnt/volume1/var/lib
rsync -av /var/lib/ /mnt/volume1/var/lib/
ls -l /mnt/volume1/var/lib/
mv /var/lib /var/lib_backup
mkdir /var/lib
mount --bind /mnt/volume1/var/lib /var/lib
```


alt: `echo "/mnt/volume1/var/lib /var/lib none bind 0 0" | sudo tee -a /etc/fstab`

#### worker-01
```

[root@ecs-worker-01 ~]# blkid /dev/nvme2n1
/dev/nvme2n1: UUID="e71a1ad4-7571-4341-a2d8-3ddb74ab809c" BLOCK_SIZE="4096" TYPE="ext4"
[root@ecs-worker-01 ~]# blkid /dev/nvme3n1
/dev/nvme3n1: UUID="04abf3ad-6e92-4d44-afa7-54c120bb9c15" BLOCK_SIZE="4096" TYPE="ext4"

vi /etc/fstab
UUID=e71a1ad4-7571-4341-a2d8-3ddb74ab809c  /mnt/volume1  ext4  defaults  0 2
UUID=04abf3ad-6e92-4d44-afa7-54c120bb9c15  /mnt/volume2  ext4  defaults  0 2
/mnt/volume1/var/lib /var/lib none bind 0 0

mount a
```

#### worker-02
```

[root@ecs-worker-02 ~]# blkid /dev/nvme2n1
/dev/nvme2n1: UUID="05b9ad4f-0a0e-4a12-9bcd-13cf124355fa" BLOCK_SIZE="4096" TYPE="ext4"
[root@ecs-worker-02 ~]# blkid /dev/nvme3n1
/dev/nvme3n1: UUID="de189720-6890-4965-9ad7-b5639bbfa792" BLOCK_SIZE="4096" TYPE="ext4"

vi /etc/fstab
UUID=05b9ad4f-0a0e-4a12-9bcd-13cf124355fa  /mnt/volume1  ext4  defaults  0 2
UUID=de189720-6890-4965-9ad7-b5639bbfa792  /mnt/volume2  ext4  defaults  0 2
/mnt/volume1/var/lib /var/lib none bind 0 0

mount -a
```

#### worker-03
```
[root@ecs-worker-03 ~]# blkid /dev/nvme2n1
/dev/nvme2n1: UUID="8b827adc-633d-484c-8bcc-1b9021c40777" BLOCK_SIZE="4096" TYPE="ext4"
[root@ecs-worker-03 ~]# blkid /dev/nvme3n1
/dev/nvme3n1: UUID="4cd9e261-f4b0-4acc-9dc5-983d1ef76e6a" BLOCK_SIZE="4096" TYPE="ext4"

vi /etc/fstab
UUID=8b827adc-633d-484c-8bcc-1b9021c40777  /mnt/volume1  ext4  defaults  0 2
UUID=4cd9e261-f4b0-4acc-9dc5-983d1ef76e6a  /mnt/volume2  ext4  defaults  0 2
/mnt/volume1/var/lib /var/lib none bind 0 0

mount -a
```

#### worker-04
```
[root@ecs-worker-04 ~]# blkid /dev/nvme2n1
/dev/nvme2n1: UUID="8581a496-ffd7-4917-b678-6487033f1d59" BLOCK_SIZE="4096" TYPE="ext4"
[root@ecs-worker-04 ~]# blkid /dev/nvme3n1
/dev/nvme3n1: UUID="00a7301e-ae34-4768-8ff7-b79d0ccacede" BLOCK_SIZE="4096" TYPE="ext4"

vi /etc/fstab
UUID=8581a496-ffd7-4917-b678-6487033f1d59  /mnt/volume1  ext4  defaults  0 2
UUID=00a7301e-ae34-4768-8ff7-b79d0ccacede  /mnt/volume2  ext4  defaults  0 2
/mnt/volume1/var/lib /var/lib none bind 0 0

mount -a
```


#### worker-05
```
[root@ecs-worker-05 ~]# blkid /dev/nvme2n1
/dev/nvme2n1: UUID="a4c1d91e-1547-41f2-bd5a-399d799e6cef" BLOCK_SIZE="4096" TYPE="ext4"
[root@ecs-worker-05 ~]# blkid /dev/nvme3n1
/dev/nvme3n1: UUID="eeb91571-a5ad-40fc-98b6-2e2d34182859" BLOCK_SIZE="4096" TYPE="ext4"

vi /etc/fstab
UUID=a4c1d91e-1547-41f2-bd5a-399d799e6cef  /mnt/volume1  ext4  defaults  0 2
UUID=eeb91571-a5ad-40fc-98b6-2e2d34182859  /mnt/volume2  ext4  defaults  0 2
/mnt/volume1/var/lib /var/lib none bind 0 0

mount -a
```


## CM Agent Install via Rulebook

https://ansible.readthedocs.io/projects/rulebook/en/latest/introduction.html


---

https://docs.ansible.com/ansible/2.9/modules/filesystem_module.html


## Notes


```
lsblk -f /dev/nvme2n1
NAME    FSTYPE LABEL UUID MOUNTPOINT

mkfs.ext4 /dev/nvme2n1

lsblk -f /dev/nvme2n1
NAME    FSTYPE LABEL UUID                                 MOUNTPOINT
nvme2n1 ext4         b94aee53-f6be-479f-971c-42ff21a65f22

mkdir -p /mnt/volume1

mount -o defaults /dev/nvme2n1 /mnt/volume1
```


```
lsblk -f /dev/nvme3n1
NAME    FSTYPE LABEL UUID MOUNTPOINT

mkfs.ext4 /dev/nvme3n1

lsblk -f /dev/nvme3n1
NAME    FSTYPE LABEL UUID                                 MOUNTPOINT
nvme3n1 ext4         042aa606-c112-499d-99aa-1062c99eda74

mkdir -p /mnt/volume2

mount -o defaults /dev/nvme3n1 /mnt/volume2
```


```
cat /etc/yum.repos.d/cloudera-manager.repo
[cloudera-manager]
name = Cloudera Manager, Version 7.11.3.2
username = ddd91ee9-0062-4a5b-8f5f-c2c1747efec5
password = b1906416f4ab
baseurl = https://ddd91ee9-0062-4a5b-8f5f-c2c1747efec5:b1906416f4ab@archive.cloudera.com/p/cm7/7.11.3.2/redhat8/yum
gpgcheck = 1
```


## ECS Install

```
cdp-release-cpx-liftie-b7bf7445-nhtv8                             2/2     Running            0             68s
cdp-release-dex-cp-595764cc4c-v4p7h                               1/2     CrashLoopBackOff   3 (8s ago)    65s
cdp-release-dmx-5b5c58886d-cq67p                                  2/3     Running            0             61s
```

```
[root@pncgf1-m-ecs-01 ~]# /var/lib/rancher/rke2/bin/kubectl --kubeconfig /etc/rancher/rke2/rke2.yaml logs cdp-release-dex-cp-685b94b576-rpqf2 -n cdp > dex-cp.logs Defaulted container "dex-cp" out of: dex-cp, fluentbit, k8tz (init) [root@pncgf1-m-ecs-01 ~]# /var/lib/rancher/rke2/bin/kubectl --kubeconfig /etc/rancher/rke2/rke2.yaml logs cdp-release-resource-pool-manager-59f55487c9-72jv4 -n cdp > resource-pool.logs Defaulted container "resource-pool-manager" out of: resource-pool-manager, fluentbit, k8tz (init)
```

```
DEX_CP=cdp-release-dex-cp-595764cc4c-v4p7h
/var/lib/rancher/rke2/bin/kubectl --kubeconfig /etc/rancher/rke2/rke2.yaml logs $DEX_CP -n cdp > dex-cp.logs
```

```
[root@ecs-master-02 ~]# cat dex-cp.logs
2024/05/15 13:44:24 Setting log level from env (LOGLEVEL)
2024/05/15 13:44:24 Log level set to: DEBUG
2024/05/15 13:44:24 Setting log format from env (LOGFORMAT)
2024/05/15 13:44:24 Log format set to: CDP
{"level":"INFO","line":"server.go:261","message":"Loaded config from: /etc/dex/conf/dex.yaml","timestamp":"2024-05-15T17:44:24Z"}
{"level":"DEBUG","line":"storage.go:56","message":"Opening database connection, driver: postgres, data source: host=cdp-embedded-db.cdp.svc.cluster.local port=5432 user=cdp-embedded-dex-user password=*** dbname=db-dex sslmode=verify-ca sslrootcert=/usr/local/share/ca-certificates/database/database.crt","timestamp":"2024-05-15T17:44:24Z"}
{"level":"FATAL","line":"db.go:226","message":"dbConn.BeginTx failed: dial tcp: lookup cdp-embedded-db.cdp.svc.cluster.local: no such host","timestamp":"2024-05-15T17:44:24Z"}
```
