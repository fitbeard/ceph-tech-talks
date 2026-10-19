#### DEMO1 ACCOUNT SCOPED CONFIGURATION
#
resource "radosgw_iam_openid_connect_provider" "demo1_keycloak" {
  provider = radosgw.demo1_account_root

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

data "radosgw_iam_openid_connect_provider" "demo1_keycloak" {
  provider = radosgw.demo1_account_root

  url = "https://keycloak.example.local/realms/demo"
}

output "demo1_keycloak_oidc_arn" {
  description = "ARN of the Demo SSO provider"
  value       = data.radosgw_iam_openid_connect_provider.demo1_keycloak.arn
}

resource "radosgw_iam_openid_connect_provider" "demo1_k8s" {
  provider = radosgw.demo1_account_root

  url = "https://kind.example.local:6443"

  client_id_list = [
    "https://kind.example.local:6443",
    "custom"
  ]

  thumbprint_list = [
    "5685C1A2EA38CD292A263C3320FCB1B9E057D0D6"
  ]
}

data "radosgw_iam_openid_connect_provider" "demo1_k8s" {
  provider = radosgw.demo1_account_root

  url = "https://kind.example.local:6443"
}

output "demo1_k8s_oidc_arn" {
  value = data.radosgw_iam_openid_connect_provider.demo1_k8s.arn
}

data "radosgw_iam_policy_document" "demo1_sso_assume_policy" {
  provider = radosgw.demo1_account_root

  statement {
    effect  = "Allow"
    actions = [
      "sts:AssumeRoleWithWebIdentity",
      "sts:TagSession"
    ]

    principals {
      type        = "Federated"
      identifiers = [
        data.radosgw_iam_openid_connect_provider.demo1_keycloak.arn
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

data "radosgw_iam_policy_document" "demo1_k8s_assume_policy" {
  provider = radosgw.demo1_account_root

  statement {
    effect  = "Allow"
    actions = [
      "sts:AssumeRoleWithWebIdentity"
    ]

    principals {
      type        = "Federated"
      identifiers = [
        data.radosgw_iam_openid_connect_provider.demo1_k8s.arn
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "kind.example.local:6443:sub"
      values   = [
        "system:serviceaccount:ceph-sts-demo:demo"
      ]
    }
  }
}

resource "radosgw_iam_role" "demo1_role_read_only" {
  provider = radosgw.demo1_account_root

  name                 = "SunriseReadOnly"
  path                 = "/sunrise-roles/"
  assume_role_policy   = data.radosgw_iam_policy_document.demo1_sso_assume_policy.json
  max_session_duration = 3600 # 1 hour

  tags = {
    project-access = "297c1aa4ef4f42bf9fdb6a7c6ced78b2:readonly" # `297c1aa4ef4f42bf9fdb6a7c6ced78b2` is an ID for OpenStack project `demo-project1` from domain `Default`
  }
}

resource "radosgw_iam_role" "demo1_role_read_write" {
  provider = radosgw.demo1_account_root

  name                 = "SunriseReadWrite"
  path                 = "/sunrise-roles/"
  assume_role_policy   = data.radosgw_iam_policy_document.demo1_sso_assume_policy.json
  max_session_duration = 3600 # 1 hour

  description          = "Some custom text"

  tags = {
    project-access = "297c1aa4ef4f42bf9fdb6a7c6ced78b2:readwrite" # `297c1aa4ef4f42bf9fdb6a7c6ced78b2` is an ID for OpenStack project `demo-project1` from domain `Default`
  }
}

resource "radosgw_iam_role" "demo1_k8s_role_read_write" {
  provider = radosgw.demo1_account_root

  name                 = "DemoKubernetesReadWrite"
  path                 = "/demo-roles/"
  assume_role_policy   = data.radosgw_iam_policy_document.demo1_k8s_assume_policy.json
  max_session_duration = 3600 # 1 hour
}

data "radosgw_iam_roles" "demo1" {
  provider = radosgw.demo1_account_root
}

output "demo1_all_role_arns" {
  description = "Demo1 all RadosGW role ARNs"
  value       = data.radosgw_iam_roles.demo1.arns
}

data "radosgw_iam_policy_document" "demo1_sunrise_read_write" {
  provider = radosgw.demo1_account_root

  statement {
    sid     = "FullAccessOnAccountBuckets"
    effect  = "Allow"
    actions = ["s3:*"]
    resources = ["*"]
  }
}

data "radosgw_iam_policy_document" "demo1_sunrise_iam_role_metadata" {
  provider = radosgw.demo1_account_root

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
      "arn:aws:iam::RGW77777777777777777:role/*"
    ]
  }
}

data "radosgw_iam_policy_document" "demo1_sunrise_iam_list_roles" {
  provider = radosgw.demo1_account_root

  statement {
    sid     = "ListRoles"
    effect  = "Allow"
    actions = [
      "iam:ListRoles"
    ]
    resources = ["*"]
  }
}

data "radosgw_iam_policy_document" "demo1_sunrise_read_only" {
  provider = radosgw.demo1_account_root

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

resource "radosgw_iam_role_policy" "demo1_sunrise_read_write" {
  provider = radosgw.demo1_account_root

  role   = radosgw_iam_role.demo1_role_read_write.name
  name   = "S3ReadWritePolicy"
  policy = data.radosgw_iam_policy_document.demo1_sunrise_read_write.json
}

resource "radosgw_iam_role_policy" "demo1_sunrise_iam_test" {
  provider = radosgw.demo1_account_root

  role   = radosgw_iam_role.demo1_role_read_write.name
  name   = "ReadRolesPolicy"
  policy = data.radosgw_iam_policy_document.demo1_sunrise_iam_role_metadata.json
}

resource "radosgw_iam_role_policy" "demo1_sunrise_iam_test2" {
  provider = radosgw.demo1_account_root

  role   = radosgw_iam_role.demo1_role_read_write.name
  name   = "ListRolesPolicy"
  policy = data.radosgw_iam_policy_document.demo1_sunrise_iam_list_roles.json
}

resource "radosgw_iam_role_policy" "demo1_sunrise_read_only" {
  provider = radosgw.demo2_account_root

  role   = radosgw_iam_role.demo1_role_read_only.name
  name   = "S3ReadOnlyPolicy"
  policy = data.radosgw_iam_policy_document.demo1_sunrise_read_only.json
}

resource "radosgw_iam_role_policy_attachment" "iam_full_access" {
  provider = radosgw.demo1_account_root

  role       = radosgw_iam_role.demo1_role_read_write.name
  policy_arn = "arn:aws:iam::aws:policy/IAMFullAccess"
}

resource "radosgw_iam_role_policy_attachment" "full_s3_access" {
  provider = radosgw.demo1_account_root

  role       = radosgw_iam_role.demo1_k8s_role_read_write.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "radosgw_s3_bucket_cors_configuration" "tadas_cors" {
  provider = radosgw.demo1_account_root

  bucket = "demo-folder1"

  cors_rule {
    id              = "sunrise-local-dev"
    allowed_headers = ["*"]
    allowed_methods = ["GET", "PUT", "DELETE", "HEAD", "POST"]
    allowed_origins = [
      "http://localhost:9990",
      "https://storage.example.local"
    ]
    expose_headers = [
      "ETag",
      "Content-Length",
      "Content-Range",
      "Last-Modified",
      "x-amz-request-id",
      "x-amz-version-id",
    ]
    max_age_seconds = 3600
  }

  cors_rule {
    allowed_methods = ["GET"]
    allowed_origins = ["*"]
  }
}

resource "radosgw_s3_bucket" "simple_demo_bucket1" {
  provider = radosgw.demo1_account_root

  bucket        = "ceph-tech-talks-bucket-demo-bucket1"
  force_destroy = true
}
