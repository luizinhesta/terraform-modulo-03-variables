# Implantação — Módulo 03

> Nada foi implantado automaticamente. Execute você mesmo.

## 1. Credenciais

```powershell
aws sso login --profile <seu-perfil>
$env:AWS_PROFILE = "<seu-perfil>"
aws sts get-caller-identity
```

## 2. Preparar variáveis

```powershell
cd etapa-01-fundamentos/modulo-03-variables/terraform
Copy-Item terraform.tfvars.example terraform.tfvars
```

Edite `terraform.tfvars` com seus dados de exibição. Lembre: serão públicos. `terraform.tfvars` é ignorado pelo Git.

## 3. Inicializar e validar

```powershell
terraform init
terraform fmt
terraform validate
```

**Evidência:** `terraform init` concluído com sucesso, reaproveitando o provider `hashicorp/aws` v6.71.0 do arquivo de lock. Também aparece o `Copy-Item` que criou o `terraform.tfvars`.

![Terraform init executado com sucesso](../imagens/imagem%20(16).png)

## 4. Planejar

```powershell
terraform plan
```

Esperado: `Plan: 10 to add, 0 to change, 0 to destroy.`

Os valores do `terraform.tfvars` foram carregados automaticamente. Confira, por exemplo, as tags do bucket.

## 5. Aplicar

```powershell
terraform apply
```

Digite `yes` após revisar. A distribuição CloudFront leva alguns minutos.

**Evidência:** o `terraform.tfvars` preenchido (perfil, tecnologias, links de contato e tags) e o `terraform apply` em andamento. A mensagem `Still creating...` da distribuição CloudFront é normal; a criação levou mais de 25 minutos neste laboratório.

![terraform.tfvars e apply criando a distribuição CloudFront](../imagens/imagem%20(19).png)

## 6. Consultar outputs

```powershell
terraform output
terraform output -raw site_url
terraform output applied_tags
terraform output -raw direct_s3_object_url
terraform output -raw bucket_arn_sensitive_demo
```

**Evidência:** saída dos outputs no terminal. Repare que `bucket_arn_sensitive_demo` aparece como `<sensitive>` no `terraform output` completo, e que `site_url`, `applied_tags` e `direct_s3_object_url` foram consultados um a um com `-raw`.

![Outputs do Terraform no terminal](../imagens/imagem%20(2).png)

**Evidência:** o site publicado na URL do CloudFront, com os valores padrão ("Seu Nome") e o selo `DEV` vindo da variável `environment`.

![Portfólio publicado no CloudFront](../imagens/imagem%20(1).png)

**Evidência:** o DevTools do navegador mostra o `config.json` sendo carregado (status 200) junto com `style.css` e `script.js`. O `favicon.ico` retorna 403 porque não existe no bucket; é esperado e não afeta o site.

![DevTools mostrando o carregamento do config.json](../imagens/imagem%20(3).png)

**Conferindo no console da AWS:** a distribuição CloudFront criada (`tfpratica-m03-dev-cdn`).

![Distribuição CloudFront no console da AWS](../imagens/imagem%20(13).png)

A origem da distribuição aponta para o bucket S3 e usa o OAC (Origin Access Control).

![Origem S3 com OAC na distribuição](../imagens/imagem%20(18).png)

O bucket S3 contém os 4 objetos: `index.html`, `style.css`, `script.js` e o `config.json` gerado pelo Terraform.

![Objetos no bucket S3](../imagens/imagem%20(14).png)

O bloqueio de acesso público do bucket está ativado, então o conteúdo só é entregue pelo CloudFront.

![Bloqueio de acesso público no S3](../imagens/imagem%20(17).png)

## 7. Alterar uma variável

Mude `profile.headline` em `terraform.tfvars`:

```powershell
terraform plan
terraform apply
```

Esperado: `~ aws_s3_object.config` (1 alteração).

**Evidência:** o plano mostra as mudanças em `profile`, `contact_links` e demais campos do `config.json`, com `Plan: 0 to add, 1 to change, 0 to destroy.` O `yes` foi digitado para confirmar.

![Apply com 1 alteração aguardando confirmação](../imagens/imagem%20(4).png)

Resultado do apply: `0 added, 1 changed, 0 destroyed.`

![Apply concluído com 1 recurso alterado](../imagens/imagem%20(7).png)

O Terraform atualiza o `config.json` no S3, mas **não limpa o cache do CloudFront**. A política de cache deste módulo usa `default_ttl_seconds` (padrão 300 segundos). Até esse tempo passar, o CloudFront pode entregar o `config.json` antigo, mesmo com o S3 já atualizado.

Você tem duas opções:

1. **Aguardar** o TTL expirar e recarregar a página.
2. **Invalidar o cache** manualmente, uma vez.

O comando de invalidação é exibido por um output, mas **o output apenas mostra o texto do comando; ele não executa nada**:

```powershell
terraform output -raw invalidation_command
```

Copie o comando exibido (algo como `aws cloudfront create-invalidation --distribution-id <ID> --paths "/*"`), cole no terminal e execute-o. Depois aguarde alguns instantes e recarregue a página (`Ctrl+F5`).

**Evidência:** invalidação criada no CloudFront para o caminho `/*`, com status `In progress`.

![Invalidação do cache criada no CloudFront](../imagens/imagem%20(5).png)

**Evidência:** após a invalidação, o site passa a exibir o novo nome e o novo texto definidos nas variáveis.

![Site atualizado com os novos valores das variáveis](../imagens/imagem%20(6).png)

Invalidações têm cota gratuita mensal; acima dela há cobrança. Execute uma vez por alteração, não em repetição.

## 8. Comparar DEV e HML (somente plano)

```powershell
terraform plan -var-file="dev.tfvars.example"
terraform plan -var-file="hml.tfvars.example"
```

Observe o que muda em relação ao state atual. **Não aplique** os dois alternadamente (veja `CONCEITOS.md`).

**Evidência:** plano com `dev.tfvars.example`: `3 to change`. Mudam só as tags (`Owner`, `Tier`, `CostCenter`) e o `Curso` é removido.

![Plano com dev.tfvars.example](../imagens/imagem%20(8).png)

**Evidência:** plano com `hml.tfvars.example`: `7 to add, 3 to change, 7 to destroy`. Como o nome do bucket inclui o ambiente, ele seria substituído. É por isso que não se aplica dev e hml no mesmo state.

![Plano com hml.tfvars.example](../imagens/imagem%20(9).png)

## 9. Destruir

Siga `DESTRUICAO.md`.

## Erros comuns

| Sintoma | Causa provável | Ação |
|---|---|---|
| `Invalid value for variable` | `validation` falhou | Corrija o valor conforme a mensagem |
| `Inappropriate value for attribute "profile"` | Falta um campo do `object` | Informe `name`, `headline` e `bio` |
| Terraform pergunta um valor no terminal | Variável sem `default` e sem tfvars | Defina em arquivo ou `-var` |
| `Value for undeclared variable` | tfvars com nome que não existe em `variables.tf` | Corrija o nome (aparece como aviso/erro) |
| `CachePolicyAlreadyExists` | Política com mesmo nome já existe | Mude `project_prefix` ou `environment` |
| `BucketAlreadyExists` | Nome em uso | Mude `project_prefix` |
| Site mostra "Carregando..." ou erro | `config.json` ausente | Confira `terraform state list` e o `plan` |
| Site mostra o texto antigo após o apply | Cache do CloudFront (TTL) | Aguarde o TTL ou copie e execute o comando de `terraform output -raw invalidation_command` |
| Bucket vai ser substituído no plan | Mudança de `environment`/`project_prefix`/região | Leia `CONCEITOS.md`, seção de ambientes |
