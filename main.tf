# CA

resource "tls_private_key" "ca_keypair" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "tls_self_signed_cert" "ca_cert" {
  is_ca_certificate     = true
  allowed_uses          = ["cert-signing"]
  key_algorithm         = tls_private_key.ca_keypair.algorithm
  private_key_pem       = tls_private_key.ca_keypair.private_key_pem
  validity_period_hours = var.ca_cert_validity_hours
  subject {
    common_name = var.ca_cn
  }
}

resource "local_file" "ca_cert" {
  filename        = "./certs/${var.ca_cn}.crt"
  content         = tls_self_signed_cert.ca_cert.cert_pem
  file_permission = "644"
}

# SERVERS

resource "tls_private_key" "server_keypair" {
  for_each  = toset(var.server_cns)
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "tls_cert_request" "server_req" {
  for_each        = toset(var.server_cns)
  key_algorithm   = tls_private_key.server_keypair[each.key].algorithm
  private_key_pem = tls_private_key.server_keypair[each.key].private_key_pem
  subject {
    common_name = each.value
  }
  dns_names = [each.value]
}

resource "tls_locally_signed_cert" "server_cert" {
  for_each              = toset(var.server_cns)
  allowed_uses          = ["server_auth"]
  ca_cert_pem           = tls_self_signed_cert.ca_cert.cert_pem
  ca_key_algorithm      = tls_private_key.ca_keypair.algorithm
  ca_private_key_pem    = tls_private_key.ca_keypair.private_key_pem
  cert_request_pem      = tls_cert_request.server_req[each.key].cert_request_pem
  validity_period_hours = var.server_cert_validity_hours
}

resource "local_file" "server_cert" {
  for_each        = toset(var.server_cns)
  filename        = "./certs/servers/${each.value}/${each.value}.crt"
  content         = tls_locally_signed_cert.server_cert[each.key].cert_pem
  file_permission = "644"
}

resource "local_file" "server_chained_cert" {
  for_each        = toset(var.server_cns)
  filename        = "./certs/servers/${each.value}/${each.value}.chained.crt"
  content         = "${tls_locally_signed_cert.server_cert[each.key].cert_pem}${tls_self_signed_cert.ca_cert.cert_pem}"
  file_permission = "644"
}

resource "local_file" "server_key" {
  for_each        = toset(var.server_cns)
  filename        = "./certs/servers/${each.value}/${each.value}.key"
  content         = tls_private_key.server_keypair[each.key].private_key_pem
  file_permission = "600"
}

# CLIENTS

resource "tls_private_key" "client_keypair" {
  for_each  = toset(var.client_cns)
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "tls_cert_request" "client_req" {
  for_each        = toset(var.client_cns)
  key_algorithm   = tls_private_key.client_keypair[each.key].algorithm
  private_key_pem = tls_private_key.client_keypair[each.key].private_key_pem
  subject {
    common_name = each.value
  }
}

resource "tls_locally_signed_cert" "client_cert" {
  for_each              = toset(var.client_cns)
  allowed_uses          = ["client_auth"]
  ca_cert_pem           = tls_self_signed_cert.ca_cert.cert_pem
  ca_key_algorithm      = tls_private_key.ca_keypair.algorithm
  ca_private_key_pem    = tls_private_key.ca_keypair.private_key_pem
  cert_request_pem      = tls_cert_request.client_req[each.key].cert_request_pem
  validity_period_hours = var.client_cert_validity_hours
}

resource "local_file" "client_cert" {
  for_each        = toset(var.client_cns)
  filename        = "./certs/clients/${each.value}/${each.value}.crt"
  content         = tls_locally_signed_cert.client_cert[each.key].cert_pem
  file_permission = "644"
}

resource "local_file" "client_key" {
  for_each        = toset(var.client_cns)
  filename        = "./certs/clients/${each.value}/${each.value}.key"
  content         = tls_private_key.client_keypair[each.key].private_key_pem
  file_permission = "600"
}

resource "pkcs12_from_pem" "client_p12" {
  for_each        = toset(var.client_cns)
  password        = var.p12_pass
  cert_pem        = tls_locally_signed_cert.client_cert[each.key].cert_pem
  private_key_pem = tls_private_key.client_keypair[each.key].private_key_pem
}

resource "local_file" "client_p12" {
  for_each       = toset(var.client_cns)
  filename       = "./certs/clients/${each.value}/${each.value}.p12"
  content_base64 = pkcs12_from_pem.client_p12[each.key].result
}
