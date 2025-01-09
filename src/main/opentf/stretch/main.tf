terraform {
  required_providers {
    equinix = {
      source = "equinix/equinix"
      version = "1.36.4"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
    ansible = {
      source  = "ansible/ansible"
      version = ">= 1.0.0"
    }
  }
}

data "external" "env" {
    program = ["${path.module}/../info.sh"]
}
output "env" {
  value = data.external.env.result
}

# Credentials for all Equinix resources
provider "equinix" {
    auth_token    = "${data.external.env.result["EQUINIX_METAL_AUTH_TOKEN"]}"
}

provider "cloudflare" {
  api_token = "${data.external.env.result["CLOUDFLARE_API_TOKEN"]}"
}


locals {
  cloudflare_zone_id = "${data.external.env.result["CLOUDFLARE_ZONE_ID"]}"  
  metal_domain = "${data.external.env.result["EQUINIX_METAL_DOMAIN"]}" 
  bastion_user = "${data.external.env.result["EQUINIX_METAL_BASTION_USER"]}"
  project_id = "${data.external.env.result["EQUINIX_METAL_PROJECT_ID"]}"
  device_plan_admin = "m3.small.x86"
  device_plan_base = "m3.large.x86"
  device_plan_kudu_master = "m3.small.x86"
  device_plan_kudu_tablet = "n3.xlarge.x86"
  device_plan_ecs_master = "c3.medium.x86"
  device_plan_ecs_worker = "n3.xlarge.x86"
}



resource "equinix_metal_project_ssh_key" "root_key" {
  name       = "root_key"
  public_key = file("/Users/rhill/root_key.pub")
  project_id = local.project_id
}


resource "equinix_metal_device" "admin_01" {
  tags             = [ "freeipa", "postgres15", "external-airflow" ]
  hostname         = "admin-01.dev.metal.zndx.org"
  plan             = local.device_plan_admin
  metro            = "da"
  operating_system = "rhel_8"
  billing_cycle    = "hourly"
  project_id       = local.project_id
  #user_ssh_key_ids = [equinix_metal_project_ssh_key.root_key.id]
  # ip_address {
  #   type = "private_ipv4"
  #   cidr = 30
  # }
}

resource "equinix_metal_device" "admin_02" {
  tags             = [ "cloudera-manager", "knox-gateway", "solr-server" ]
  hostname         = "admin-02.dev.metal.zndx.org"
  plan             = local.device_plan_admin
  metro            = "da"
  operating_system = "rhel_8"
  billing_cycle    = "hourly"
  #user_ssh_key_ids = [equinix_metal_project_ssh_key.root_key.id]
  project_id       = local.project_id 
  # ip_address {
  #   type = "private_ipv4"
  #   cidr = 30
  # }
}


########
# Base Cluster Nodes (3-10)
########

resource "equinix_metal_device" "base_01" {
  tags             = [ "atlas", "ranger", "solr", "hive" ]
  hostname         = "base-01.dev.metal.zndx.org"
  plan             = local.device_plan_base
  metro            = "da"
  operating_system = "rhel_8"
  billing_cycle    = "hourly"
  #user_ssh_key_ids = [equinix_metal_project_ssh_key.root_key.id]
  project_id       = local.project_id
  # ip_address {
  #   type = "private_ipv4"
  #   cidr = 30
  # }
}

resource "equinix_metal_device" "base_02" {
  tags             = [ "hive-on-tez", "kafka", "hbase" ]
  hostname         = "base-02.dev.metal.zndx.org"
  plan             = local.device_plan_base
  metro            = "da"
  operating_system = "rhel_8"
  billing_cycle    = "hourly"
  #user_ssh_key_ids = [equinix_metal_project_ssh_key.root_key.id]
  project_id       = local.project_id
  # ip_address {
  #   type = "private_ipv4"
  #   cidr = 30
  # }
}

resource "equinix_metal_device" "base_03" {
  tags             = [ "zookeeper", "yarn", "tez", "hbase" ]
  hostname         = "base-03.dev.metal.zndx.org"
  plan             = local.device_plan_base
  metro            = "da"
  operating_system = "rhel_8"
  billing_cycle    = "hourly"
  #user_ssh_key_ids = [equinix_metal_project_ssh_key.root_key.id]
  project_id       = local.project_id
  # ip_address {
  #   type = "private_ipv4"
  #   cidr = 30
  # }
}

########
# Kudu Master Nodes (1-3)
# https://kudu.apache.org/docs/command_line_tools_reference.html#perf
# use_upsert; use_random_pk
# https://cloudera.atlassian.net/wiki/spaces/ENG/pages/100829674/Kudu+Benchmarks+Dashboards
# https://cloudera.atlassian.net/wiki/spaces/ENG/pages/100828797/YCSB+on+6+nodes
########

  resource "equinix_metal_device" "kudu_master_00" {
    tags             = [ "kudu-master" ]
    hostname         = "kudu-master-00.metal.zndx.org"
    plan             = "c3.small.x86"
    metro            = "da"
    operating_system = "rhel_8"
    billing_cycle    = "hourly"
    project_id       = "${data.external.env.result["EQUINIX_METAL_PROJECT_ID"]}"
  }
  resource "equinix_metal_device" "kudu_master_01" {
    tags             = [ "kudu-master" ]
    hostname         = "kudu-master-00.metal.zndx.org"
    plan             = "c3.small.x86"
    metro            = "da"
    operating_system = "rhel_8"
    billing_cycle    = "hourly"
    project_id       = "${data.external.env.result["EQUINIX_METAL_PROJECT_ID"]}"
  }
  resource "equinix_metal_device" "kudu_master_02" {
    tags             = [ "kudu-master" ]
    hostname         = "kudu-master-00.metal.zndx.org"
    plan             = "c3.small.x86"
    metro            = "da"
    operating_system = "rhel_8"
    billing_cycle    = "hourly"
    project_id       = "${data.external.env.result["EQUINIX_METAL_PROJECT_ID"]}"
  }

########
# Kudu Tablet Server Nodes (5-250)
########

resource "equinix_metal_device" "kudu_ts_00" {
    tags             = [ "kudu-tablet-server" ]
    hostname         = "kudu-ts-00.metal.zndx.org"
    plan             = "n2.xlarge.x86"
    metro            = "da"
    operating_system = "rhel_8"
    billing_cycle    = "hourly"
    project_id       = "${data.external.env.result["EQUINIX_METAL_PROJECT_ID"]}"
  }

resource "equinix_metal_device" "kudu_ts_01" {
    tags             = [ "kudu-tablet-server" ]
    hostname         = "kudu-ts-01.metal.zndx.org"
    plan             = "n2.xlarge.x86"
    metro            = "da"
    operating_system = "rhel_8"
    billing_cycle    = "hourly"
    project_id       = "${data.external.env.result["EQUINIX_METAL_PROJECT_ID"]}"
  }

resource "equinix_metal_device" "kudu_ts_02" {
    tags             = [ "kudu-tablet-server" ]
    hostname         = "kudu-ts-02.metal.zndx.org"
    plan             = "n2.xlarge.x86"
    metro            = "da"
    operating_system = "rhel_8"
    billing_cycle    = "hourly"
    project_id       = "${data.external.env.result["EQUINIX_METAL_PROJECT_ID"]}"
  }

resource "equinix_metal_device" "kudu_ts_03" {
    tags             = [ "kudu-tablet-server" ]
    hostname         = "kudu-ts-02.metal.zndx.org"
    plan             = "n2.xlarge.x86"
    metro            = "da"
    operating_system = "rhel_8"
    billing_cycle    = "hourly"
    project_id       = "${data.external.env.result["EQUINIX_METAL_PROJECT_ID"]}"
  }

resource "equinix_metal_device" "kudu_ts_04" {
    tags             = [ "kudu-tablet-server" ]
    hostname         = "kudu-ts-02.metal.zndx.org"
    plan             = "n2.xlarge.x86"
    metro            = "da"
    operating_system = "rhel_8"
    billing_cycle    = "hourly"
    project_id       = "${data.external.env.result["EQUINIX_METAL_PROJECT_ID"]}"
  }



########
# Ozone Manager Nodes (3)
########

  resource "equinix_metal_device" "ozone_om_00" {
    tags             = [ "ozone-manager" ]
    hostname         = "ozone-om-00.metal.zndx.org"
    plan             = "n3.xlarge.x86"
    metro            = "da"
    operating_system = "rhel_8"
    billing_cycle    = "hourly"
    project_id       = "${data.external.env.result["EQUINIX_METAL_PROJECT_ID"]}"
  }

  # resource "equinix_metal_device" "ozone_om_01" {
  #   hostname         = "ozone-om-01.metal.zndx.org"
  #   plan             = "m3.large.x86"
  #   metro            = "da"
  #   operating_system = "rhel_8"
  #   billing_cycle    = "hourly"
  #   project_id       = "${data.external.env.result["EQUINIX_METAL_PROJECT_ID"]}"
  # }

  # resource "equinix_metal_device" "ozone_om_02" {
  #   hostname         = "ozone-om-02.metal.zndx.org"
  #   plan             = "m3.large.x86"
  #   metro            = "da"
  #   operating_system = "rhel_8"
  #   billing_cycle    = "hourly"
  #   project_id       = "${data.external.env.result["EQUINIX_METAL_PROJECT_ID"]}"
  # }

########
# Ozone Storage Container Manager Nodes (3)
########

  resource "equinix_metal_device" "ozone_scm_00" {
    tags             = [ "ozone-storage-container-manager" ]
    hostname         = "ozone-scm-00.metal.zndx.org"
    plan             = "n3.xlarge.x86"
    metro            = "da"
    operating_system = "rhel_8"
    billing_cycle    = "hourly"
    project_id       = "${data.external.env.result["EQUINIX_METAL_PROJECT_ID"]}"
  }

  # resource "equinix_metal_device" "ozone_scm_01" {
  #   hostname         = "ozone-scm-01.metal.zndx.org"
  #   plan             = "m3.large.x86"
  #   metro            = "da"
  #   operating_system = "rhel_8"
  #   billing_cycle    = "hourly"
  #   project_id       = "${data.external.env.result["EQUINIX_METAL_PROJECT_ID"]}"
  # }

  # resource "equinix_metal_device" "ozone_scm_02" {
  #   hostname         = "ozone-scm-02.metal.zndx.org"
  #   plan             = "m3.large.x86"
  #   metro            = "da"
  #   operating_system = "rhel_8"
  #   billing_cycle    = "hourly"
  #   project_id       = "${data.external.env.result["EQUINIX_METAL_PROJECT_ID"]}"
  # }

########
# Ozone Data Nodes (5-48 to *many*)
########

  resource "equinix_metal_device" "ozone_data_000" {
    tags             = [ "ozone-data" ]
    hostname         = "ozone-data-000.metal.zndx.org"
    plan             = "s3.xlarge.x86"
    metro            = "da"
    operating_system = "rhel_8"
    billing_cycle    = "hourly"
    project_id       = "${data.external.env.result["EQUINIX_METAL_PROJECT_ID"]}"
  }

  resource "equinix_metal_device" "ozone_data_001" {
    tags             = [ "ozone-data" ]
    hostname         = "ozone-data-001.metal.zndx.org"
    plan             = "s3.xlarge.x86"
    metro            = "da"
    operating_system = "rhel_8"
    billing_cycle    = "hourly"
    project_id       = "${data.external.env.result["EQUINIX_METAL_PROJECT_ID"]}"
  }

  resource "equinix_metal_device" "ozone_data_002" {
    tags             = [ "ozone-data" ]
    hostname         = "ozone-data-002.metal.zndx.org"
    plan             = "s3.xlarge.x86"
    metro            = "da"
    operating_system = "rhel_8"
    billing_cycle    = "hourly"
    project_id       = "${data.external.env.result["EQUINIX_METAL_PROJECT_ID"]}"
  }

  # resource "equinix_metal_device" "ozone_data_003" {
  #   hostname         = "ozone-data-003.metal.zndx.org"
  #   plan             = "s3.xlarge.x86"
  #   metro            = "da"
  #   operating_system = "rhel_8"
  #   billing_cycle    = "hourly"
  #   project_id       = "${data.external.env.result["EQUINIX_METAL_PROJECT_ID"]}"
  # }

  # resource "equinix_metal_device" "ozone_data_004" {
  #   hostname         = "ozone-data-004.metal.zndx.org"
  #   plan             = "s3.xlarge.x86"
  #   metro            = "da"
  #   operating_system = "rhel_8"
  #   billing_cycle    = "hourly"
  #   project_id       = "${data.external.env.result["EQUINIX_METAL_PROJECT_ID"]}"
  # }



########
# ECS Nodes (5-22)
#  Customer queries + generated data
########

resource "equinix_metal_device" "ecs_master_01" {
  tags             = [ "ecs-master" ]
  hostname         = "ecs-master-01.dev.metal.zndx.org"
  plan             = local.device_plan_ecs_master
  metro            = "da"
  operating_system = "rhel_8"
  billing_cycle    = "hourly"
  project_id       = local.project_id
  # ip_address {
  #   type = "private_ipv4"
  #   cidr = 30
  # }
}

resource "equinix_metal_device" "ecs_master_02" {
  tags             = [ "ecs-master" ]
  hostname         = "ecs-master-02.dev.metal.zndx.org"
  plan             = local.device_plan_ecs_master
  metro            = "da"
  operating_system = "rhel_8"
  billing_cycle    = "hourly"
  project_id       = local.project_id
  # ip_address {
  #   type = "private_ipv4"
  #   cidr = 30
  # }
}


resource "equinix_metal_device" "ecs_master_03" {
  tags             = [ "ecs-master" ]
  hostname         = "ecs-master-03.dev.metal.zndx.org"
  plan             = local.device_plan_ecs_master
  metro            = "da"
  operating_system = "rhel_8"
  billing_cycle    = "hourly"
  project_id       = local.project_id
  # ip_address {
  #   type = "private_ipv4"
  #   cidr = 30
  # }
}


resource "equinix_metal_device" "ecs_worker_01" {
  tags             = [ "ecs-worker" ]
  hostname         = "ecs-worker-01.dev.metal.zndx.org"
  plan             = local.device_plan_ecs_worker
  metro            = "da"
  operating_system = "rhel_8"
  billing_cycle    = "hourly"
  project_id       = local.project_id
  # ip_address {
  #   type = "private_ipv4"
  #   cidr = 30
  # }
}

resource "equinix_metal_device" "ecs_worker_02" {
  tags             = [ "ecs-worker" ]
  hostname         = "ecs-worker-02.dev.metal.zndx.org"
  plan             = local.device_plan_ecs_worker
  metro            = "da"
  operating_system = "rhel_8"
  billing_cycle    = "hourly"
  project_id       = local.project_id
  # ip_address {
  #   type = "private_ipv4"
  #   cidr = 30
  # }
}

resource "equinix_metal_device" "ecs_worker_03" {
  tags             = [ "ecs-worker" ]
  hostname         = "ecs-worker-03.dev.metal.zndx.org"
  plan             = local.device_plan_ecs_worker
  metro            = "da"
  operating_system = "rhel_8"
  billing_cycle    = "hourly"
  project_id       = local.project_id
  # ip_address {
  #   type = "private_ipv4"
  #   cidr = 30
  # }
}


resource "equinix_metal_device" "ecs_worker_04" {
  tags             = [ "ecs-worker" ]
  hostname         = "ecs-worker-04.dev.metal.zndx.org"
  plan             = local.device_plan_ecs_worker
  metro            = "da"
  operating_system = "rhel_8"
  billing_cycle    = "hourly"
  project_id       = local.project_id
  # ip_address {
  #   type = "private_ipv4"
  #   cidr = 30
  # }
}


# ------- Ansible Inventory  -------

resource "ansible_group" "bastion" {
  name = "jump_host"
}

resource "ansible_group" "freeipa" {
  name = "freeipa"
}

resource "ansible_group" "db" {
  name = "db_server"
}

resource "ansible_group" "pg15" {
  name = "pg15_server"
}

resource "ansible_group" "cm" {
  name = "cloudera_manager"
}

resource "ansible_group" "workers" {
  name = "cluster_workers"
  variables = {
    host_template = "Workers"
  }
}

resource "ansible_group" "masters" {
  name = "cluster_masters"
  variables = {
    host_template = "Masters"
  }
}

resource "ansible_group" "cluster" {
  name = "cluster"
  children = [
    ansible_group.masters.name,
    ansible_group.workers.name
  ]
  variables = {
    tls = "True"
  }
}

resource "ansible_group" "deployment" {
  name = "deployment"
  children = [
    ansible_group.cluster.name,
    ansible_group.cm.name,
    ansible_group.db.name,
    ansible_group.freeipa.name
  ]
  variables = {
    ansible_ssh_common_args = "-o ProxyCommand='ssh -i {{ lookup('ansible.builtin.env', 'SSH_PRIVATE_KEY_FILE') }} -o User=${local.bastion_user} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -W %h:%p -q ${local.metal_domain}'"
  }
}

