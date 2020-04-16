# Configure provider with your Cisco ACI credentials
provider "aci" {
  # Cisco ACI user name
  username = "admin"
  # Cisco ACI password
  password = "C1sco12345"
  # Cisco ACI URL
  url      = "https://198.18.133.200"
  insecure = true
}

# Tenant Definition
resource "aci_tenant" "terraform_tenant" {
  name        = "terraform_tenant"
  name_alias  = "tenant_for_terraform"
  description = "This tenant is created by terraform ACI provider"
}

# Networkin Definition
resource "aci_bridge_domain" "bd_for_subnet" {
  tenant_dn   = "${aci_tenant.terraform_tenant.id}"
  name        = "bd_for_subnet"
  description = "This bridge domain is created by terraform ACI provider"
  mac         = "00:22:BD:F8:19:FF"
}

resource "aci_subnet" "demosubnet" {
  bridge_domain_dn                    = "${aci_bridge_domain.bd_for_subnet.id}"
  ip                                  = "10.0.3.28/27"
  scope                               = "private"
  description                         = "This subject is created by terraform"
  ctrl                                = "unspecified"
  preferred                           = "no"
  virtual                             = "yes"
}

# App Profile Definition
resource "aci_application_profile" "terraform_app" {
  tenant_dn  = "${aci_tenant.terraform_tenant.id}"
  name       = "terraform_app"
  name_alias = "demo_ap"
  prio       = "level1"
}

# EPG Definitions
resource "aci_application_epg" "web" {
  application_profile_dn  = "${aci_application_profile.terraform_app.id}"
  name                    = "web"
  name_alias              = "web_epg"
}

resource "aci_application_epg" "app" {
  application_profile_dn  = "${aci_application_profile.terraform_app.id}"
  name                    = "app"
  name_alias              = "web_epg"
}

resource "aci_application_epg" "db_cache" {
  application_profile_dn  = "${aci_application_profile.terraform_app.id}"
  name                    = "db_cache"
  name_alias              = "db_cache_epg"
}
resource "aci_application_epg" "db" {
  application_profile_dn  = "${aci_application_profile.terraform_app.id}"
  name                    = "db"
  name_alias              = "db_epg"
}
resource "aci_application_epg" "log" {
  application_profile_dn  = "${aci_application_profile.terraform_app.id}"
  name                    = "log"
  name_alias              = "log_epg"
}
resource "aci_application_epg" "auth" {
  application_profile_dn  = "${aci_application_profile.terraform_app.id}"
  name                    = "auth"
  name_alias              = "auth_epg"
}

# Contract Definitions
resource "aci_contract" "web_to_app" {
  tenant_dn = "${aci_tenant.tenant.id}"
  name      = "web_to_app"
  scope     = "tenant"
}

resource "aci_contract" "app_to_db" {
  tenant_dn = "${aci_tenant.tenant.id}"
  name      = "app_to_db"
  scope     = "tenant"
}

resource "aci_contract" "app_to_auth" {
  tenant_dn = "${aci_tenant.tenant.id}"
  name      = "app_to_auth"
  scope     = "tenant"
}

resource "aci_contract" "cache_to_db" {
  tenant_dn = "${aci_tenant.tenant.id}"
  name      = "cache_to_db"
  scope     = "tenant"
}

resource "aci_contract" "any_to_log" {
  tenant_dn = "${aci_tenant.tenant.id}"
  name      = "any_to_log"
  scope     = "tenant"
}

# Subject Definitions
resource "aci_contract_subject" "only_web_secure_traffic" {
  contract_dn                  = "${aci_contract.web_to_app.id}"
  name                         = "only_web_secure_traffic"
  relation_vz_rs_subj_filt_att = ["${aci_filter.https_traffic.name}"]
}

resource "aci_contract_subject" "only_db_traffic" {
  contract_dn                  = "${aci_contract.app_to_db.id}"
  name                         = "only_db_traffic"
  relation_vz_rs_subj_filt_att = ["${aci_filter.db_traffic.name}"]
}

resource "aci_contract_subject" "only_auth_traffic" {
  contract_dn                  = "${aci_contract.app_to_auth.id}"
  name                         = "only_auth_traffic"
  relation_vz_rs_subj_filt_att = ["${aci_filter.https_traffic.name}"]
}

resource "aci_contract_subject" "only_log_traffic" {
  contract_dn                  = "${aci_contract.any_to_log.id}"
  name                         = "only_log_traffic"
  relation_vz_rs_subj_filt_att = ["${aci_filter.https_traffic.name}"]
}

resource "aci_contract_subject" "only_db_cache_traffic" {
  contract_dn                  = "${aci_contract.cache_to_db.id}"
  name                         = "only_db_cache_traffic"
  relation_vz_rs_subj_filt_att = ["${aci_filter.db_traffic.name}"]
}

# Contract Filters
## HTTPS Traffic
resource "aci_filter" "https_traffic" {
  tenant_dn = "${aci_tenant.tenant.id}"
  name      = "https_traffic"
}

resource "aci_filter_entry" "https" {
  filter_dn   = "${aci_filter.https_traffic.id}"
  name        = "https"
  ether_t     = "ip"
  prot        = "tcp"
  # Note using `443` here works, but is represented as `https` in the model
  # Using `https` prevents TF trying to set it to `443` every run
  d_from_port = "https"
  d_to_port   = "https"
}
## DB Traffic
resource "aci_filter" "db_traffic" {
  tenant_dn = "${aci_tenant.tenant.id}"
  name      = "db_traffic"
}

resource "aci_filter_entry" "mariadb" {
  filter_dn   = "${aci_filter.db_traffic.id}"
  name        = "mariadb"
  ether_t     = "ip"
  prot        = "tcp"
  d_from_port = "3306"
  d_to_port   = "3306"
}