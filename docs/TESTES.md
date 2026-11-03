# Testes — Módulo 03

Preencha **Resultado obtido** com o que observar. Não há resultados de execução pré-preenchidos.

| # | Teste | Como executar | Resultado esperado | Resultado obtido |
|---|---|---|---|---|
| 1 | Init/validate | `terraform init`, `terraform validate` | Válido | |
| 2 | Plano padrão | `terraform plan` | `10 to add` | |
| 3 | Validação de prefixo | `terraform plan -var="project_prefix=ABC_x"` | Erro com a mensagem personalizada | |
| 4 | Validação de ambiente | `terraform plan -var="environment=prod"` | Erro: deve ser dev ou hml | |
| 5 | Validação de TTL | `terraform plan -var="default_ttl_seconds=999999"` | Erro: entre 0 e 86400 | |
| 6 | Plano DEV | `terraform plan -var-file="dev.tfvars.example"` | Plano executa; `Environment = "dev"` nas tags | |
| 7 | Plano HML | `terraform plan -var-file="hml.tfvars.example"` | Plano executa; nome do bucket com `-hml-` | |
| 8 | Apply | `terraform apply` | `10 added` | |
| 9 | Site HTTPS | Abrir `terraform output -raw site_url` | Portfólio com nome, projetos, tecnologias e contatos | |
| 10 | Badge de ambiente | Ver topo da página | Mostra o valor de `environment` | |
| 11 | Outputs | `terraform output` | Bucket, ARN, `direct_s3_object_url`, distribuição, tags; ARN sensível oculto | |
| 12 | Output sensível | `terraform output -raw bucket_arn_sensitive_demo` | Mostra o ARN | |
| 13 | S3 privado | Abrir `terraform output -raw direct_s3_object_url` (sem autenticação) | `403 AccessDenied`; o site continua abrindo pelo CloudFront (teste 9) | |
| 14 | Mudança de variável no Terraform | Alterar `profile.headline`, `plan`, `apply` | `plan` com 1 `~` em `aws_s3_object.config`; `apply` com `1 changed` | |
| 15 | Mudança refletida no site | Recarregar o site; se mostrar o texto antigo, aguardar o TTL (`default_ttl_seconds`) ou copiar e executar o comando exibido por `terraform output -raw invalidation_command`, e recarregar com `Ctrl+F5` | Texto novo visível. O texto antigo logo após o apply é esperado por causa do cache do CloudFront | |
| 16 | Sem divergência | `terraform plan` | `No changes.` | |
| 17 | Destroy | `terraform destroy` | `10 destroyed` | |

O comando `terraform output -raw invalidation_command` apenas **exibe** o comando; a invalidação só ocorre quando você o executa.

Verificação opcional com curl (o primeiro deve dar `200`; o segundo, `403`):

```powershell
curl.exe -I (terraform output -raw site_url)
curl.exe -I (terraform output -raw direct_s3_object_url)
```

## Evidências

| Teste | Evidência |
|---|---|
| 1 | [terraform init](../imagens/imagem%20(16).png) |
| 6 | [Plano DEV](../imagens/imagem%20(8).png) |
| 7 | [Plano HML](../imagens/imagem%20(9).png) |
| 8 | [Apply em andamento](../imagens/imagem%20(19).png) |
| 9 e 10 | [Site com badge DEV](../imagens/imagem%20(1).png) e [DevTools com config.json](../imagens/imagem%20(3).png) |
| 11 e 12 | [Outputs](../imagens/imagem%20(2).png) |
| 13 | [Bloqueio de acesso público no S3](../imagens/imagem%20(17).png) |
| 14 | [Apply com 1 alteração](../imagens/imagem%20(7).png) |
| 15 | [Invalidação](../imagens/imagem%20(5).png) e [site atualizado](../imagens/imagem%20(6).png) |
| 17 | [Destroy](../imagens/imagem%20(15).png) |

Exemplo visual do teste 9 (site publicado):

![Site publicado no CloudFront](../imagens/imagem%20(1).png)

## Critérios de sucesso

- [ ] As três validações falharam como esperado.
- [ ] Você comparou DEV e HML via `-var-file` sem aplicar.
- [ ] Você consulta a URL com `terraform output`.
- [ ] Você explica por que `sensitive` não protege o state.
