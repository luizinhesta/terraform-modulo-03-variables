# -----------------------------------------------------------------------------
# main.tf - Módulo 03: portfólio parametrizado
#
# A arquitetura é a mesma do módulo 02 (S3 privado + CloudFront + OAC).
# O que muda: valores fixos viram variáveis (veja variables.tf).
# -----------------------------------------------------------------------------

data "aws_caller_identity" "current" {}

locals {
  # Nome base reutilizado em todos os recursos: prefixo + ambiente.
  name_prefix = "${var.project_prefix}-${var.environment}"

  # Nome do bucket (limite de 63 caracteres; o prefixo validado ajuda a respeitar).
  bucket_name = "${local.name_prefix}-${data.aws_caller_identity.current.account_id}-${var.aws_region}"

  # merge() combina maps; em chaves repetidas, o ÚLTIMO map vence.
  # O operador condicional (cond ? a : b) só inclui Owner se a variável não for null.
  tags = merge(
    {
      Environment = var.environment
    },
    var.owner == null ? {} : { Owner = var.owner },
    var.extra_tags
  )

  application_path = "${path.module}/../application"

  content_types = {
    ".html" = "text/html; charset=utf-8"
    ".css"  = "text/css; charset=utf-8"
    ".js"   = "application/javascript; charset=utf-8"
    ".json" = "application/json; charset=utf-8"
  }

  site_files = fileset(local.application_path, "**")

  # Conteúdo do config.json: gerado A PARTIR das variáveis.
  # O script.js do site lê este arquivo e monta a página.
  site_config = {
    environment   = var.environment
    profile       = var.profile
    technologies  = var.technologies
    projects      = var.projects
    contact_links = var.contact_links
  }
}

# 1) Bucket privado -----------------------------------------------------------
resource "aws_s3_bucket" "site" {
  bucket        = local.bucket_name
  force_destroy = true

  tags = merge(local.tags, { Name = "${local.name_prefix}-bucket" })
}

resource "aws_s3_bucket_public_access_block" "site" {
  bucket = aws_s3_bucket.site.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

# 2) Política de cache própria, controlada pela variável default_ttl_seconds ----
resource "aws_cloudfront_cache_policy" "site" {
  name        = "${local.name_prefix}-cache"
  comment     = "TTL padrao definido pela variavel default_ttl_seconds"
  default_ttl = var.default_ttl_seconds
  min_ttl     = 0
  max_ttl     = 31536000

  parameters_in_cache_key_and_forwarded_to_origin {
    enable_accept_encoding_gzip   = true
    enable_accept_encoding_brotli = true

    cookies_config {
      cookie_behavior = "none"
    }
    headers_config {
      header_behavior = "none"
    }
    query_strings_config {
      query_string_behavior = "none"
    }
  }
}

# 3) OAC ----------------------------------------------------------------------
resource "aws_cloudfront_origin_access_control" "site" {
  name                              = "${local.name_prefix}-oac"
  description                       = "OAC do portfolio (${var.environment})"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# 4) Distribuição CloudFront --------------------------------------------------
resource "aws_cloudfront_distribution" "site" {
  enabled             = true
  comment             = "${local.name_prefix} - Terraform na Pratica Modulo 03"
  default_root_object = "index.html"
  price_class         = var.price_class
  is_ipv6_enabled     = var.enable_ipv6

  origin {
    origin_id                = "s3-site"
    domain_name              = aws_s3_bucket.site.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.site.id
  }

  default_cache_behavior {
    target_origin_id       = "s3-site"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true
    cache_policy_id        = aws_cloudfront_cache_policy.site.id
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = merge(local.tags, { Name = "${local.name_prefix}-cdn" })
}

# 5) Bucket policy ------------------------------------------------------------
resource "aws_s3_bucket_policy" "site" {
  bucket = aws_s3_bucket.site.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PermitirLeituraSomenteDoCloudFront"
        Effect    = "Allow"
        Principal = { Service = "cloudfront.amazonaws.com" }
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.site.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.site.arn
          }
        }
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.site]
}

# 6) Arquivos estáticos -------------------------------------------------------
resource "aws_s3_object" "files" {
  for_each = local.site_files

  bucket = aws_s3_bucket.site.id
  key    = each.value
  source = "${local.application_path}/${each.value}"
  etag   = filemd5("${local.application_path}/${each.value}")

  content_type = lookup(
    local.content_types,
    try(regex("\\.[^.]+$", each.value), ""),
    "application/octet-stream"
  )
}

# 7) config.json gerado pelo Terraform ---------------------------------------
# "content" recebe texto direto (sem arquivo local). Se uma variável mudar,
# o conteúdo muda e o plano mostra ~ update in-place neste objeto.
resource "aws_s3_object" "config" {
  bucket       = aws_s3_bucket.site.id
  key          = "config.json"
  content      = jsonencode(local.site_config)
  content_type = "application/json; charset=utf-8"
}
