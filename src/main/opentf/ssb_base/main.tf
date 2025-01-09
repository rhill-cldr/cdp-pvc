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

# output "env" {
#   value = data.external.env.result
# }

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
  device_plan_otel = "m3.large.x86"
  device_plan_kudu_master = "m3.small.x86"
  device_plan_kudu_tablet = "n3.xlarge.x86"
  device_plan_ecs_master = "c3.medium.x86"
  device_plan_ecs_worker = "n3.xlarge.x86"
  cdp_os = "rhel_9"
  ipa_os = "rhel_8"
}


# resource "equinix_metal_vlan" "cdp_dev_vlan" {
#   description = "VLAN in Dallas"
#   metro       = "da"
#   project_id  = local.project_id
#   vxlan       = 1000
# }

# resource "equinix_metal_device_network_type" "cdp_dev_proxy_0" {
#   device_id = equinix_metal_device.proxy_0.id
#   type      = "hybrid"
# }

# resource "equinix_metal_device_network_type" "cdp_dev_admin_0" {
#   device_id = equinix_metal_device.admin_0.id
#   type      = "hybrid"
# }

# resource "equinix_metal_port_vlan_attachment" "cdp_dev_proxy_0_vlan" {
#   device_id = equinix_metal_device_network_type.cdp_dev_proxy_0.id
#   port_name = "eth1"
#   vlan_vnid = equinix_metal_vlan.cdp_dev_vlan.vxlan
# }

# resource "equinix_metal_port_vlan_attachment" "cdp_dev_admin_0_vlan" {
#   device_id = equinix_metal_device_network_type.cdp_dev_admin_0.id
#   port_name = "eth1"
#   vlan_vnid = equinix_metal_vlan.cdp_dev_vlan.vxlan
# }

# resource "equinix_metal_gateway" "cdp_dev_gw" {
#   project_id       = local.project_id
#   vlan_id           = equinix_metal_vlan.cdp_dev_vlan.id
#   ip_reservation_id = "d43c6239-8fa8-4781-a643-e9e6aa139c28" 
# }


# - preserve naming for ${module.bastion.host.public_ip} 
# resource "equinix_metal_device" "bastion" {
#   tags             =  [ "bastion" ]
#   hostname         = "bastion.metal.zndx.org"
#   plan             = "m3.small.x86"
#   metro            = "da"
#   operating_system = local.cdp_os
#   billing_cycle    = "hourly"
#   project_id       = local.project_id
# }

# resource "equinix_metal_device" "proxy_0" {
#   tags             =  [ "haproxy", "varnish", "electric-sql-server" ]
#   hostname         = "metal.zndx.org"
#   plan             = local.device_plan_admin 
#   metro            = "da"
#   operating_system = local.cdp_os
#   billing_cycle    = "hourly"
#   project_id       = local.project_id
# }


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
  operating_system = local.ipa_os
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
  operating_system = local.cdp_os
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
  operating_system = local.cdp_os
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
  operating_system = local.cdp_os
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
  operating_system = local.cdp_os
  billing_cycle    = "hourly"
  #user_ssh_key_ids = [equinix_metal_project_ssh_key.root_key.id]
  project_id       = local.project_id
  # ip_address {
  #   type = "private_ipv4"
  #   cidr = 30
  # }
}

resource "equinix_metal_device" "base_04" {
  tags             = [ "zookeeper", "yarn", "tez", "hbase" ]
  hostname         = "base-04.dev.metal.zndx.org"
  plan             = local.device_plan_base
  metro            = "da"
  operating_system = local.cdp_os
  billing_cycle    = "hourly"
  #user_ssh_key_ids = [equinix_metal_project_ssh_key.root_key.id]
  project_id       = local.project_id
  # ip_address {
  #   type = "private_ipv4"
  #   cidr = 30
  # }
}

resource "equinix_metal_device" "base_05" {
  tags             = [ "zookeeper", "yarn", "tez", "hbase" ]
  hostname         = "base-05.dev.metal.zndx.org"
  plan             = local.device_plan_base
  metro            = "da"
  operating_system = local.cdp_os
  billing_cycle    = "hourly"
  #user_ssh_key_ids = [equinix_metal_project_ssh_key.root_key.id]
  project_id       = local.project_id
  # ip_address {
  #   type = "private_ipv4"
  #   cidr = 30
  # }
}

########
# Observability Cluster Nodes (5)
########

# resource "equinix_metal_device" "otel_01" {
#   tags             = [ "observability" ]
#   hostname         = "otel-01.dev.metal.zndx.org"
#   plan             = local.device_plan_otel
#   metro            = "da"
#   operating_system = local.cdp_os
#   billing_cycle    = "hourly"
#   project_id       = local.project_id
#   #user_ssh_key_ids = [equinix_metal_project_ssh_key.root_key.id]
#   # ip_address {
#   #   type = "private_ipv4"
#   #   cidr = 30
#   # }
# }


# resource "equinix_metal_device" "otel_02" {
#   tags             = [ "observability" ]
#   hostname         = "otel-02.dev.metal.zndx.org"
#   plan             = local.device_plan_otel
#   metro            = "da"
#   operating_system = local.cdp_os
#   billing_cycle    = "hourly"
#   project_id       = local.project_id
#   #user_ssh_key_ids = [equinix_metal_project_ssh_key.root_key.id]
#   # ip_address {
#   #   type = "private_ipv4"
#   #   cidr = 30
#   # }
# }


# resource "equinix_metal_device" "otel_03" {
#   tags             = [ "observability" ]
#   hostname         = "otel-03.dev.metal.zndx.org"
#   plan             = local.device_plan_otel
#   metro            = "da"
#   operating_system = local.cdp_os
#   billing_cycle    = "hourly"
#   project_id       = local.project_id
#   #user_ssh_key_ids = [equinix_metal_project_ssh_key.root_key.id]
#   # ip_address {
#   #   type = "private_ipv4"
#   #   cidr = 30
#   # }
# }


# resource "equinix_metal_device" "otel_04" {
#   tags             = [ "observability" ]
#   hostname         = "otel-04.dev.metal.zndx.org"
#   plan             = local.device_plan_otel
#   metro            = "da"
#   operating_system = local.cdp_os
#   billing_cycle    = "hourly"
#   project_id       = local.project_id
#   #user_ssh_key_ids = [equinix_metal_project_ssh_key.root_key.id]
#   # ip_address {
#   #   type = "private_ipv4"
#   #   cidr = 30
#   # }
# }


# resource "equinix_metal_device" "otel_05" {
#   tags             = [ "observability" ]
#   hostname         = "otel-05.dev.metal.zndx.org"
#   plan             = local.device_plan_otel
#   metro            = "da"
#   operating_system = local.cdp_os
#   billing_cycle    = "hourly"
#   project_id       = local.project_id
#   #user_ssh_key_ids = [equinix_metal_project_ssh_key.root_key.id]
#   # ip_address {
#   #   type = "private_ipv4"
#   #   cidr = 30
#   # }
# }

# ------- Cloudflare DNS  -------


resource "cloudflare_record" "admin_01_dns" {
  zone_id = local.cloudflare_zone_id
  name    = "admin-01.dev.metal"
  value   = equinix_metal_device.admin_01.access_public_ipv4
  type    = "A"
  ttl     = 600
  proxied = false
}

resource "cloudflare_record" "admin_02_dns" {
  zone_id = local.cloudflare_zone_id
  name    = "admin-02.dev.metal"
  value   = equinix_metal_device.admin_02.access_public_ipv4
  type    = "A"
  ttl     = 600
  proxied = false
}

# ------- Base Cluster DNS -------

resource "cloudflare_record" "base_01_dns" {
  zone_id = local.cloudflare_zone_id
  name    = "base-01.dev.metal"
  value   = equinix_metal_device.base_01.access_public_ipv4
  type    = "A"
  ttl     = 600
  proxied = false
}

resource "cloudflare_record" "base_02_dns" {
  zone_id = local.cloudflare_zone_id
  name    = "base-02.dev.metal"
  value   = equinix_metal_device.base_02.access_public_ipv4
  type    = "A"
  ttl     = 600
  proxied = false
}

resource "cloudflare_record" "base_03_dns" {
  zone_id = local.cloudflare_zone_id
  name    = "base-03.dev.metal"
  value   = equinix_metal_device.base_03.access_public_ipv4
  type    = "A"
  ttl     = 600
  proxied = false
}

resource "cloudflare_record" "base_04_dns" {
  zone_id = local.cloudflare_zone_id
  name    = "base-04.dev.metal"
  value   = equinix_metal_device.base_04.access_public_ipv4
  type    = "A"
  ttl     = 600
  proxied = false
}

resource "cloudflare_record" "base_05_dns" {
  zone_id = local.cloudflare_zone_id
  name    = "base-05.dev.metal"
  value   = equinix_metal_device.base_05.access_public_ipv4
  type    = "A"
  ttl     = 600
  proxied = false
}

# ------- OTel Cluster DNS -------

# resource "cloudflare_record" "otel_01_dns" {
#   zone_id = local.cloudflare_zone_id
#   name    = "otel-01.dev.metal"
#   value   = equinix_metal_device.otel_01.access_public_ipv4
#   type    = "A"
#   ttl     = 600
#   proxied = false
# }

# resource "cloudflare_record" "otel_02_dns" {
#   zone_id = local.cloudflare_zone_id
#   name    = "otel-02.dev.metal"
#   value   = equinix_metal_device.otel_02.access_public_ipv4
#   type    = "A"
#   ttl     = 600
#   proxied = false
# } 

# resource "cloudflare_record" "otel_03_dns" {
#   zone_id = local.cloudflare_zone_id
#   name    = "otel-03.dev.metal"
#   value   = equinix_metal_device.otel_03.access_public_ipv4
#   type    = "A"
#   ttl     = 600
#   proxied = false
# } 

# resource "cloudflare_record" "otel_04_dns" {
#   zone_id = local.cloudflare_zone_id
#   name    = "otel-04.dev.metal"
#   value   = equinix_metal_device.otel_04.access_public_ipv4
#   type    = "A"
#   ttl     = 600
#   proxied = false
# } 

# resource "cloudflare_record" "otel_05_dns" {
#   zone_id = local.cloudflare_zone_id
#   name    = "otel-05.dev.metal"
#   value   = equinix_metal_device.otel_05.access_public_ipv4
#   type    = "A"
#   ttl     = 600
#   proxied = false
# } 

# ------- Ansible Inventory  -------

# resource "ansible_group" "bastion" {
#   name = "jump_host"
# }

# resource "ansible_group" "freeipa" {
#   name = "freeipa"
# }

# resource "ansible_group" "admin_db" {
#   name = "admin_db_server"
# }

# resource "ansible_group" "pg15" {
#   name = "pg15_server"
# }

# resource "ansible_group" "cm" {
#   name = "cloudera_manager"
# }

# resource "ansible_group" "workers" {
#   name = "cluster_workers"
#   variables = {
#     host_template = "Workers"
#   }
# }

# resource "ansible_group" "masters" {
#   name = "cluster_masters"
#   variables = {
#     host_template = "Masters"
#   }
# }

# resource "ansible_group" "cluster" {
#   name = "cluster"
#   children = [
#     ansible_group.masters.name,
#     ansible_group.workers.name
#   ]
#   variables = {
#     tls = "True"
#   }
# }

# resource "ansible_group" "deployment" {
#   name = "deployment"
#   children = [
#     ansible_group.cluster.name,
#     ansible_group.cm.name,
#     ansible_group.admin_db.name,
#     ansible_group.freeipa.name
#   ]
#   variables = {
#     ansible_ssh_common_args = "-o ProxyCommand='ssh -i {{ lookup('ansible.builtin.env', 'SSH_PRIVATE_KEY_FILE') }} -o User=${local.bastion_user} -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -W %h:%p -q ${local.metal_domain}'"
#   }
# }
