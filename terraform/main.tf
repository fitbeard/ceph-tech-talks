#### GLOBAL RADOSGW CONFIGURATION

#### RGW ACCOUNT DEMO1
resource "radosgw_iam_account" "demo1" {
  provider = radosgw.global_admin

  account_id      = "RGW77777777777777777"
  name            = "demo1"
  email           = "demo1@example.com"
  max_users       = 100
  max_roles       = 25
  max_buckets     = 500
  max_access_keys = 8
}

resource "radosgw_iam_user" "demo1_root" {
  provider = radosgw.global_admin

  user_id      = "demo1-root"
  display_name = "AccountAdmin"
  account_id   = radosgw_iam_account.demo1.account_id
  account_root = true
}

resource "radosgw_iam_access_key" "demo1_root" {
  provider = radosgw.global_admin

  user_id = radosgw_iam_user.demo1_root.user_id
}

#### RGW ACCOUNT DEMO2
resource "radosgw_iam_account" "demo2" {
  provider = radosgw.global_admin

  name  = "demo2"
  email = "demo2@example.com"
}

resource "radosgw_iam_user" "demo2_root" {
  provider = radosgw.global_admin

  user_id      = "demo2-root"
  display_name = "AccountAdmin"
  account_id   = radosgw_iam_account.demo2.account_id
  account_root = true
}

resource "radosgw_iam_access_key" "demo2_root" {
  provider = radosgw.global_admin

  user_id = radosgw_iam_user.demo2_root.user_id
}
