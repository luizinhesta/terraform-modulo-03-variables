# -----------------------------------------------------------------------------
# outputs.tf - Saídas do módulo
# Consulte depois do apply com: terraform output [nome]
# -----------------------------------------------------------------------------
output "site_url" {
  description = "URL HTTPS do portfólio."
  value       = "https://${aws_cloudfront_distribution.site.domain_name}"
}

output "environment" {
  description = "Ambiente lógico aplicado."
  value       = var.environment
}

output "bucket_name" {
  description = "Nome do bucket S3."
  value       = aws_s3_bucket.site.id
}

output "bucket_arn" {
  description = "ARN do bucket S3."
  value       = aws_s3_bucket.site.arn
}

output "bucket_regional_domain_name" {
  description = "Endpoint REST do bucket (origem do CloudFront)."
  value       = aws_s3_bucket.site.bucket_regional_domain_name
}

output "direct_s3_object_url" {
  description = "URL direta de um objeto S3. Deve retornar 403: o bucket é privado."
  value       = "https://${aws_s3_bucket.site.bucket_regional_domain_name}/index.html"
}

output "distribution_id" {
  description = "ID da distribuição CloudFront."
  value       = aws_cloudfront_distribution.site.id
}

output "distribution_domain_name" {
  description = "Domínio padrão da distribuição CloudFront."
  value       = aws_cloudfront_distribution.site.domain_name
}

output "applied_tags" {
  description = "Tags definidas pelo módulo no bucket."
  value       = aws_s3_bucket.site.tags
}

output "invalidation_command" {
  description = "Comando para invalidar o cache (execute manualmente, quando necessário)."
  value       = "aws cloudfront create-invalidation --distribution-id ${aws_cloudfront_distribution.site.id} --paths \"/*\""
}

# -----------------------------------------------------------------------------
# Demonstração de "sensitive".
# Com sensitive = true o Terraform oculta o valor no terminal (mostra <sensitive>).
# ATENÇÃO: isso NÃO criptografa nada. O valor continua em texto puro no state.
# Aqui usamos o ARN apenas para ENSINAR o comportamento; o ARN não é segredo.
# Para ler: terraform output -raw bucket_arn_sensitive_demo
# -----------------------------------------------------------------------------
output "bucket_arn_sensitive_demo" {
  description = "Exemplo didático de output sensível."
  value       = aws_s3_bucket.site.arn
  sensitive   = true
}
