# Destruição — Módulo 03

## Procedimento

Use os **mesmos** arquivos de variáveis do apply. Isso evita que o Terraform calcule nomes diferentes dos que existem.

```powershell
cd etapa-01-fundamentos/modulo-03-variables/terraform
aws sts get-caller-identity
terraform plan -destroy
terraform destroy
```

Se você usou `-var-file` ou `-var` no apply, use os mesmos no destroy. O `terraform.tfvars` é carregado sozinho.

Esperado: `Destroy complete! Resources: 10 destroyed.`

**Evidência:** a distribuição CloudFront levou cerca de 3 minutos para ser destruída. Em seguida foram removidos o OAC, a cache policy e o bucket, terminando em `Destroy complete! Resources: 10 destroyed.`

![Terraform destroy concluído com 10 recursos destruídos](../imagens/imagem%20(15).png)

## Custos

| Recurso | Pode gerar custo? |
|---|---|
| CloudFront (requisições, transferência) | Sim, acima do free tier |
| Invalidações | Sim, acima da cota mensal gratuita |
| S3 | Sim, valores muito baixos |
| OAC, cache policy, policy, public access block | Não |

## Cuidados e limitações

- Se você aplicou um ambiente e depois trocou `environment` sem aplicar, o state ainda refere o ambiente anterior. O `destroy` usará as variáveis atuais para avaliar o código, mas remove o que está no state.
- `force_destroy = true` apaga todos os objetos do bucket.
- Não apague `terraform.tfstate` antes do destroy.
- `terraform.tfvars` não é versionado; guarde uma cópia se quiser reaplicar o mesmo perfil.

## Verificar

```powershell
aws s3 ls | Select-String "tfpratica-m03"
```

Deve retornar vazio.
