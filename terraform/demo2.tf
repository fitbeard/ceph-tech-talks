#### DEMO2 ACCOUNT SCOPED CONFIGURATION
#
resource "radosgw_iam_openid_connect_provider" "demo2_keycloak" {
  provider = radosgw.demo2_account_root

  url = "https://keycloak.example.local/realms/demo"

  client_id_list = [
    "account",
    "rgw-client-public-browser",
    "sunrise-server"
  ]

  thumbprint_list = [
    "D9CBAAC78E6B1F2086BF43A45E62F0CEA6A89C1A",
    "D27B80268674AA755AAC525788FAB322CADAD83E"
  ]
}

data "radosgw_iam_openid_connect_provider" "demo2_keycloak" {
  provider = radosgw.demo2_account_root

  url = "https://keycloak.example.local/realms/demo"
}

output "demo2_keycloak_oidc_arn" {
  description = "ARN of the Demo SSO provider"
  value       = data.radosgw_iam_openid_connect_provider.demo2_keycloak.arn
}

data "radosgw_iam_policy_document" "demo2_sso_assume_policy" {
  provider = radosgw.demo2_account_root

  statement {
    effect  = "Allow"
    actions = [
      "sts:AssumeRoleWithWebIdentity",
      "sts:TagSession"
    ]

    principals {
      type        = "Federated"
      identifiers = [
        data.radosgw_iam_openid_connect_provider.demo2_keycloak.arn
      ]
    }

    condition {
      test     = "ForAnyValue:StringEquals"
      variable = "aws:RequestTag/project-access"
      values   = [
        "$${iam:ResourceTag/project-access}"
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "keycloak.example.local/realms/demo:aud"
      values   = [
        "account",
        "rgw-client-public-browser",
        "sunrise-server"
      ]
    }
  }
}

resource "radosgw_iam_role" "demo2_role_read_only" {
  provider = radosgw.demo2_account_root

  name                 = "SunriseReadOnly"
  path                 = "/sunrise-roles/"
  assume_role_policy   = data.radosgw_iam_policy_document.demo2_sso_assume_policy.json
  max_session_duration = 3600 # 1 hour

  tags = {
    project-access = "37c05c43a57d419097dce9eee2769027:readonly" # `37c05c43a57d419097dce9eee2769027` is an ID for OpenStack project `services` from domain `service`
  }
}

resource "radosgw_iam_role" "demo2_role_read_write" {
  provider = radosgw.demo2_account_root

  name                 = "SunriseReadWrite"
  path                 = "/sunrise-roles/"
  assume_role_policy   = data.radosgw_iam_policy_document.demo2_sso_assume_policy.json
  max_session_duration = 3600 # 1 hour

  description          = "Some custom text"

  tags = {
    project-access = "37c05c43a57d419097dce9eee2769027:readwrite" # `37c05c43a57d419097dce9eee2769027` is an ID for OpenStack project `services` from domain `service`
  }
}

data "radosgw_iam_roles" "demo2" {
  provider = radosgw.demo2_account_root
}

output "demo2_all_role_arns" {
  description = "demo2 all RadosGW role ARNs"
  value       = data.radosgw_iam_roles.demo2.arns
}

data "radosgw_iam_policy_document" "demo2_sunrise_read_write" {
  provider = radosgw.demo2_account_root

  statement {
    sid     = "FullAccessOnAccountBuckets"
    effect  = "Allow"
    actions = ["s3:*"]
    resources = ["*"]
  }
}

data "radosgw_iam_policy_document" "demo2_sunrise_iam_role_metadata" {
  provider = radosgw.demo2_account_root

  statement {
    sid     = "ReadRoleMetadata"
    effect  = "Allow"
    actions = [
      "iam:GetRole",
      "iam:GetRolePolicy",
      "iam:ListRolePolicies",
      "iam:ListAttachedRolePolicies"
    ]
    resources = [
      "arn:aws:iam::RGW97317822198395516:role/*"
    ]
  }
}

data "radosgw_iam_policy_document" "demo2_sunrise_iam_list_roles" {
  provider = radosgw.demo2_account_root

  statement {
    sid     = "ListRoles"
    effect  = "Allow"
    actions = [
      "iam:ListRoles"
    ]
    resources = ["*"]
  }
}

data "radosgw_iam_policy_document" "demo2_sunrise_read_only" {
  provider = radosgw.demo2_account_root

  statement {
    sid     = "ListAllMyBuckets"
    effect  = "Allow"
    actions = ["s3:ListAllMyBuckets"]
    resources = ["*"]
  }

  statement {
    sid     = "ReadOnlyOnAccountBuckets"
    effect  = "Allow"
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetObjectTagging",
      "s3:ListBucket",
      "s3:ListBucketVersions",
      "s3:GetBucketLocation",
      "s3:GetBucketTagging"
    ]
    resources = ["*"]
  }
}

resource "radosgw_iam_role_policy" "demo2_sunrise_read_write" {
  provider = radosgw.demo2_account_root

  role   = radosgw_iam_role.demo2_role_read_write.name
  name   = "S3ReadWritePolicy"
  policy = data.radosgw_iam_policy_document.demo2_sunrise_read_write.json
}

resource "radosgw_iam_role_policy" "demo2_sunrise_iam_test" {
  provider = radosgw.demo2_account_root

  role   = radosgw_iam_role.demo2_role_read_write.name
  name   = "ReadRolesPolicy"
  policy = data.radosgw_iam_policy_document.demo2_sunrise_iam_role_metadata.json
}

resource "radosgw_iam_role_policy" "demo2_sunrise_iam_test2" {
  provider = radosgw.demo2_account_root

  role   = radosgw_iam_role.demo2_role_read_write.name
  name   = "ListRolesPolicy"
  policy = data.radosgw_iam_policy_document.demo2_sunrise_iam_list_roles.json
}

resource "radosgw_iam_role_policy" "demo2_sunrise_read_only" {
  provider = radosgw.demo2_account_root

  role   = radosgw_iam_role.demo2_role_read_only.name
  name   = "S3ReadOnlyPolicy"
  policy = data.radosgw_iam_policy_document.demo2_sunrise_read_only.json
}

# resource "radosgw_iam_role_policy_attachment" "iam_full_access" {
#   provider = radosgw.demo2_account_root
#
#   role       = radosgw_iam_role.demo2_role_read_write.name
#   policy_arn = "arn:aws:iam::aws:policy/IAMFullAccess"
# }

resource "radosgw_s3_bucket" "simple_demo_bucket2" {
  provider = radosgw.demo2_account_root

  bucket = "ceph-tech-talks-bucket-demo-bucket2"
}
