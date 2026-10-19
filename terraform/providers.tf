terraform {
  required_providers {
    radosgw = {
      source = "fitbeard/radosgw"
    }
  }
  required_version = "1.9.1"
}

provider "radosgw" {
  alias      = "global_admin"
  endpoint   = var.rgw_endpoint
  access_key = var.rgw_access_key_id
  secret_key = var.rgw_secret_access_key
}

provider "radosgw" {
  alias      = "demo1_account_root"
  endpoint   = var.rgw_endpoint
  access_key = radosgw_iam_access_key.demo1_root.access_key
  secret_key = radosgw_iam_access_key.demo1_root.secret_key
}

provider "radosgw" {
  alias      = "demo2_account_root"
  endpoint   = var.rgw_endpoint
  access_key = radosgw_iam_access_key.demo2_root.access_key
  secret_key = radosgw_iam_access_key.demo2_root.secret_key
}
