# Residência, Trilha Foundation

Repositório evolutivo da Trilha Foundation da Residência DevOps na Nuvem. O
mesmo projeto acompanha o aluno durante as 12 sprints e recebe novas capacidades
sem descartar o que já foi construído.

## Estrutura do repositório

```text
residencia-trilha-foundation/
├── site/                              # SPA React e TypeScript
├── backend/
│   └── lambdas/
│       ├── 01-catalog-backend-api-lambda/
│       ├── 02-order-backend-api-lambda/
│       └── 03-order-processor-lambda/
└── infrastructure/
    ├── catch-up/                      # baselines cumulativos em CloudFormation
    │   ├── baselines/
    │   └── components/
    └── terraform/                     # IaC criada durante a trilha
        ├── bootstrap.sh
        ├── foundation/
        └── stacks/
```

Catch-up e Terraform possuem ciclos de vida diferentes. O catch-up entrega os
pré-requisitos para uma pessoa entrar na sprint atual. O diretório Terraform
recebe apenas as stacks que forem implementadas como parte dos desafios.

| Necessidade | Caminho | Ferramenta |
| --- | --- | --- |
| Entrar em uma sprint já iniciada | `infrastructure/catch-up` | CloudFormation |
| Executar os desafios atuais | `site` e `backend` | Console da AWS e código da aplicação |
| Construir IaC quando ela entrar na trilha | `infrastructure/terraform` | Terraform |

Não existem profiles Terraform por sprint. Os pontos de entrada ficam somente
nos baselines do catch-up.

## Catch-up para quem entra na Sprint 2

Quem começa diretamente na Sprint 2 pode preparar o resultado funcional da
Sprint 1 sem executar o laboratório anterior. O catch-up cria um bucket S3
privado e uma distribuição CloudFront por CloudFormation, gera o frontend em
modo mock e publica os arquivos. Ele usa a URL padrão do CloudFront, sem domínio
customizado.

```bash
AWS_PROFILE=seu-profile \
  ./infrastructure/catch-up/bootstrap.sh apply ready-for-sprint-02
```

Esse fluxo prepara o ambiente; ele não substitui o conteúdo ou as evidências da
Sprint 1. Consulte [infrastructure/catch-up/README.md](infrastructure/catch-up/README.md)
para acompanhar os eventos, verificar o ambiente ou removê-lo.

## Catch-up, tags e Terraform

Existem três conceitos independentes:

- a tag do Git determina a versão do código disponível naquele ponto da trilha;
- um baseline de catch-up prepara os pré-requisitos de quem entra em uma sprint;
- uma root stack Terraform representa infraestrutura construída pelo residente.

O início de cada sprint será marcado por uma tag. Assim, uma pessoa que entrar
diretamente na Sprint 6 poderá usar `start-sprint-06`. Essa versão já conterá o
resultado esperado até a Sprint 5, sem exigir a execução dos laboratórios
anteriores. Quem quiser executar a Sprint 5 poderá usar `start-sprint-05`, que
conterá o ponto anterior à implementação daquele desafio.

```text
start-sprint-05  -> ponto inicial para implementar a infraestrutura do frontend
start-sprint-06  -> frontend da Sprint 5 pronto; início do próximo desafio
```

A `main` representa o ponto mais recente já liberado. As tags preservam os
pontos anteriores sem duplicar diretórios ou manter uma branch por sprint.

### Quando Terraform entrar na trilha

Não existem profiles Terraform por sprint. Cada root stack aparece somente no
momento em que passa a fazer parte do conteúdo e evolui no mesmo diretório nas
sprints seguintes. O state continua independente por stack:

```text
residencia-foundation/01-web-edge.tfstate
residencia-foundation/02-identity.tfstate
residencia-foundation/03-marketplace-api.tfstate
```

Uma stack é executada explicitamente, sem associá-la a um baseline:

```bash
RESIDENCIA_STATE_BUCKET=meu-state-bucket \
  ./infrastructure/terraform/bootstrap.sh apply 01-web-edge
```

Ao chegar à sprint que introduz Terraform, remova primeiro o ambiente equivalente
criado pelo catch-up. CloudFormation e Terraform não devem administrar os mesmos
recursos simultaneamente. Consulte
[infrastructure/terraform/README.md](infrastructure/terraform/README.md) para a
convenção das root stacks e do state.

Fazer checkout de uma tag não altera a conta AWS. Antes de voltar para uma tag
anterior, remova o baseline ou as stacks atualmente provisionadas.

## Sprint 1: criar seu fork

No GitHub, abra o repositório original e selecione **Fork**. Depois clone o seu
fork, substituindo `SEU-USUARIO` pelo seu usuário do GitHub:

```bash
git clone https://github.com/SEU-USUARIO/residencia-trilha-foundation.git
cd residencia-trilha-foundation
git remote add upstream https://github.com/kenerry-serain/residencia-trilha-foundation.git
```

O remote `origin` aponta para o seu fork. O remote `upstream` aponta para o
repositório da Residência e será usado para receber as próximas sprints.

## Sprint 2 em diante: atualizar seu fork

Antes de começar uma nova sprint, entre no repositório local e traga a versão
mais recente da Residência:

```bash
cd residencia-trilha-foundation
git checkout main
git pull upstream main
git push origin main
```

O `pull` atualiza seu clone local com o conteúdo liberado no repositório
original. O `push` leva essa atualização para o seu fork no GitHub.

## Executar o site localmente

```bash
npm --prefix site install
npm --prefix site run dev
```

O endereço local padrão é `http://localhost:5173`.

## Autenticação

No desenvolvimento local, o site usa autenticação e dados mock:

```env
VITE_APP_MODE=mock
```

O formulário aceita qualquer e-mail válido e uma senha com pelo menos seis
caracteres. O modo local permite validar cadastro de produto, compra, estoque e
pedidos sem criar recursos na AWS. Nesse modo, sessão, produtos e pedidos ficam
no `localStorage` daquele navegador. Um selo visível identifica o ambiente como
`Mock mode · dados locais`.

Na Sprint 2, o frontend já está preparado para cadastro, confirmação de e-mail,
login, primeiro acesso, recuperação de senha e restauração da sessão pelo
Amazon Cognito. Informe:

```env
VITE_APP_MODE=production
VITE_AWS_REGION=us-east-1
VITE_COGNITO_USER_POOL_ID=us-east-1_xxxxxxxxx
VITE_COGNITO_CLIENT_ID=xxxxxxxxxxxxxxxxxxxxxxxxxx
VITE_API_URL=https://xxxxxxxxxx.execute-api.us-east-1.amazonaws.com/prod
```

O arquivo [`site/.env.sprint-02.example`](site/.env.sprint-02.example) já contém
esse modelo. Copie-o para `site/.env.production.local`, preencha os valores dos
recursos criados no laboratório e gere um novo build.

Depois da autenticação, todas as chamadas ao API Gateway enviam o ID token
JWT no cabeçalho `Authorization: Bearer <token>`.

Com `VITE_APP_MODE=production`, o frontend não usa os dados locais. O selo muda
para `Production · AWS` e as operações passam a usar Cognito e API Gateway.

O carrinho permanece no navegador, separado por usuário, até a conclusão da
compra. Produtos, estoque e pedidos usam a API. Cada produto aceita até oito
imagens; o DynamoDB guarda a lista de chaves e os arquivos permanecem no S3.

## Backend da Sprint 2

O código das três Lambdas e a SPA do marketplace já estão prontos. O trabalho
do aluno é empacotar, publicar e conectar os recursos pelo Console da AWS.

| Lambda | Runtime | Responsabilidade |
| --- | --- | --- |
| `catalog-backend-api-lambda` | TypeScript (Node.js 24) | Consultar e cadastrar produtos no DynamoDB e gerar URLs temporárias para imagens no S3 |
| `order-backend-api-lambda` | .NET 8 | Consultar compras e vendas, gravar o pedido como `pending` e publicar o evento na SQS |
| `order-processor-lambda` | TypeScript (Node.js 24) | Consumir a SQS, baixar o estoque e confirmar o pedido numa transação do DynamoDB |

Na Sprint 2, as Lambdas usam `DATA_SOURCE=dynamodb`. A tabela substitui o mock
em memória e torna o fluxo consistente entre Lambdas e cold starts. Os adapters
para RDS continuam separados e poderão ser ativados depois com
`DATA_SOURCE=rds` e as variáveis de conexão, sem alterar os handlers.

Consulte [backend/README.md](backend/README.md) para conhecer os packages, os
handlers e as variáveis de ambiente.

## Build de produção do site

```bash
npm --prefix site run build
```

Os arquivos estáticos serão gerados em `site/dist` e poderão ser enviados para
o bucket S3 da Sprint 1.

## Testes realizados: DynamoDB e RDS

Registro da branch `feature/sprint03`, consolidado em **04/11/2026**, na região
`us-east-1`. Os testes manuais do laboratório foram confrontados com logs do
CloudWatch, configuração das funções e leitura de um pedido no DynamoDB.
Esta documentação não executou novas compras nem alterou recursos AWS.
Todos os horários abaixo estão em **UTC**.

Os eventos selecionados, seus IDs e log streams estão no arquivo de
[evidências dos adapters](docs/evidencias/data-source-2026-11-04.json).
O arquivo contém uma amostra rastreável, sem senhas, tokens ou dados pessoais
dos compradores; não é uma exportação completa dos logs.

### Resultados observados

| Cenário | Resultado | Evidência |
| --- | --- | --- |
| `DATA_SOURCE=dynamodb`: processamento de pedido | Confirmado | Evento `order-processed` em 14/10/2026 às 02:05:37.088 e item correspondente consultado com `status=processed` na tabela `residencia-foundation-marketplace`. |
| `DATA_SOURCE=rds`: processamento e atualização de estoque | Confirmado pelo retorno do adapter após o commit | Em 04/11/2026 às 23:09:36.444, pedido processado com estoque resultante `985`; às 23:12:29.469, outro pedido processado com estoque resultante `0`. |
| `DATA_SOURCE=rds`: reentrega da mesma mensagem | Duplicidade reconhecida | O mesmo `messageId` e `orderId` retornaram `duplicate` às 23:10:06.084 e 23:10:35.804. |
| Conectividade RDS Proxy → PostgreSQL | Disponível na inspeção | Target `AVAILABLE`; instância `residencia-marketplace-postgres` disponível, banco inicial `marketplace`, acesso público desabilitado e Single-AZ. |

#### Evidência DynamoDB

Grupo de logs: `/aws/lambda/order-processor-lambda`. Trecho do evento de
14/10/2026 às 02:05:37.088:

```text
orderId: '341bc055-0c6b-4847-a22e-4be493058c1f'
result: {
  status: 'processed',
  orderId: '341bc055-0c6b-4847-a22e-4be493058c1f',
  productId: '7de2a6c2-3cd6-4409-98f7-db5d3eefb071',
  quantity: 1
}
```

A leitura consistente de `ORDER#341bc055-0c6b-4847-a22e-4be493058c1f`
confirmou `status=processed`, o mesmo produto e quantidade `1`. Isso confirma
o registro persistido do pedido; não foi capturado um comparativo de estoque
antes/depois para esse exemplo histórico.

#### Evidência RDS

No mesmo grupo de logs, em 04/11/2026 às 23:09:36.444:

```text
messageId: '55d2ca72-9dc8-44e5-bb0e-fd1363e81cfc'
orderId: 'e9defc4d-0250-43a3-a661-c363d966b362'
result: {
  status: 'processed',
  orderId: 'e9defc4d-0250-43a3-a661-c363d966b362',
  stock: 985
}
```

Às 23:10:06.084 e 23:10:35.804, a mesma mensagem retornou:

```text
result: {
  status: 'duplicate',
  orderId: 'e9defc4d-0250-43a3-a661-c363d966b362'
}
```

O [adapter RDS](backend/lambdas/03-order-processor-lambda/src/processors/rds-order-processor.ts)
retorna `stock` após o `COMMIT`. Ao encontrar o pedido já processado, retorna
`duplicate` antes de executar outra baixa de estoque. Esses registros evidenciam
o processamento e a proteção contra reentrega naquele cenário; a causa das
reentregas não foi investigada nesta coleta.

Os logs históricos não incluem o valor de `DATA_SOURCE`. A identificação do
adapter RDS utiliza o campo `stock` do retorno, específico desse adapter no
código revisado, e o contexto da correção do deploy. Não foi realizada uma
consulta SQL independente às linhas do RDS durante a coleta das evidências.

### Problemas encontrados e correções verificadas

1. **Conexão pelo CloudShell antes de o target estar disponível.** A tentativa
   inicial com `psql` retornou `server closed the connection unexpectedly`.
   O teste foi repetido após o target do proxy ficar `AVAILABLE`, e a resolução
   foi confirmada durante o laboratório. Verificar o target, não apenas o
   status geral do proxy, antes de aplicar o schema.

Não foi necessário adicionar usuário ou senha às variáveis da Lambda.
O papel de execução já permitia `secretsmanager:GetSecretValue` para o secret
do banco. `correlationId: undefined` não era a causa da falha de conexão.

### Alternância dos adapters e reprodução

Na coleta de 04/11/2026, o processor já estava novamente com
`DATA_SOURCE=dynamodb`; sua última atualização registrada era 23:13:47 UTC.
Esse estado atual não substitui as evidências históricas do teste RDS.

Para repetir a validação, configure **as três Lambdas** para a mesma fonte de
dados, conforme [backend/README.md](backend/README.md):

- DynamoDB: `DATA_SOURCE=dynamodb` e `MARKETPLACE_TABLE_NAME`.
- RDS: `DATA_SOURCE=rds`, `DB_HOST` apontando para o RDS Proxy, `DB_PORT=5432`,
  `DB_NAME=marketplace`, `DB_SECRET_ARN` e `DB_SSL=true`.

Antes da troca, aguarde o processamento das mensagens pendentes e verifique a
DLQ para evitar consumir eventos de uma base usando o outro adapter. A troca
de `DATA_SOURCE` não migra produtos ou pedidos entre DynamoDB e PostgreSQL.

1. No modo escolhido, cadastre um produto e anote o estoque inicial.
2. Faça uma compra e anote o `orderId`.
3. Confira o pedido como `processed`, o estoque final e o evento correspondente
   no CloudWatch. Para RDS, use também uma consulta SQL pelo CloudShell na VPC;
   para DynamoDB, confira os itens `PRODUCT#<id>` e `ORDER#<id>`.
4. Preserve horário UTC, IDs e resultados para comparar as duas execuções.

Para localizar os registros no CloudWatch Logs Insights, selecione o grupo
`/aws/lambda/order-processor-lambda` e o intervalo de datas do teste:

```sql
fields @timestamp, @logStream, @message
| filter @message like /order-processed|order-processing-failed/
| sort @timestamp asc
| limit 200
```

## Acesso administrativo ao banco: bastion e Session Manager

Registro da branch `feature/sprint03`, em **08/11/2026 e 09/11/2026 (UTC)**, na
região `us-east-1`.

### Desafio 1: bastion host com SSH

Um bastion é uma instância numa subnet pública que funciona como único ponto de
entrada para recursos em subnets privadas. Foi usado para executar `psql` contra
o endpoint privado do RDS Proxy sem tornar o banco público.

| Recurso | Configuração |
| --- | --- |
| Subnet `residencia-public-bastion-a` | `10.0.0.128/27`, `us-east-1a` |
| Internet Gateway `internet-gateway-bastion` | Anexado à `residencia-marketplace-vpc` |
| Route table `residencia-public-rt` | `0.0.0.0/0 → IGW`, associada **somente** à subnet do bastion |
| EC2 `residencia-bastion-2` | `t3.micro`, Amazon Linux 2023, IPv4 público, IMDSv2 obrigatório |
| `residencia-bastion-sg` | Inbound SSH 22 apenas do IP do aluno em `/32` |
| `residencia-proxy-sg` | Inbound TCP 5432 com origem no SG do bastion (sem CIDR) |

As subnets das Lambdas e do banco continuaram associadas à
`residencia-private-rt`, sem rota para o Internet Gateway.

### Desafio 2: Session Manager no lugar do SSH

A instância virou managed instance do Systems Manager:

1. O SSM Agent já vem no Amazon Linux 2023 (versão `3.3.5708.0`).
2. Instance profile `residencia-bastion-ssm-role` com
   `AmazonSSMManagedInstanceCore`.
3. Sessão testada pelo console **antes** de remover a regra de SSH; depois, o
   inbound do `residencia-bastion-sg` ficou vazio.
4. Túnel aberto na máquina local com o Session Manager plugin:

```bash
aws ssm start-session --region us-east-1 \
  --target <instance-id> \
  --document-name AWS-StartPortForwardingSessionToRemoteHost \
  --parameters '{"host":["<endpoint-do-rds-proxy>"],"portNumber":["5432"],"localPortNumber":["15432"]}'
```

5. Com a sessão aberta, o `psql` local conectou em `127.0.0.1:15432`. Sem
   Homebrew, o cliente foi executado via Docker:

```bash
docker run --rm -it postgres:16 \
  psql "host=host.docker.internal port=15432 dbname=marketplace user=<usuario> sslmode=require"
```

Use `sslmode=require`: o proxy exige TLS, e `verify-full` falharia porque o
certificado é emitido para o nome do proxy, não para `127.0.0.1`.

#### Observação: DHMC

A conta já tinha o Default Host Management Configuration ativado por um Quick
Setup. Por isso a instância aparecia `Online` no Systems Manager antes mesmo do
instance profile, e o SSM continuou reportando o role do DHMC
(`AWS-QuickSetup-SSM-DefaultEC2MgmtRole-us-east-1`) após a associação e o
restart do agente. O túnel funcionou nos dois casos.

### Por que o port forwarding reduz a superfície de ataque

| | Porta 22 pública | Port forwarding do Session Manager |
| --- | --- | --- |
| Porta de entrada | sshd exposto à internet, sujeito a varredura e força bruta | Nenhuma; o agente abre conexões **de saída** em HTTPS 443 |
| Autenticação | Chave `.pem` estática, copiável | IAM (`ssm:StartSession`), com MFA e revogação imediata |
| Escopo | Shell completo na instância | Apenas o host e a porta definidos no documento |
| Auditoria | Logs locais, apagáveis por um invasor | Cada sessão registrada no CloudTrail |
| Exposição de rede | Exige IP público | IP público dispensável com Interface endpoints (`ssm`, `ssmmessages`, `ec2messages`) ou NAT |

O bastion com SSH também acrescenta custo e risco operacional: IPv4 público
cobrado, patching do SO, rotação de chaves, atualização do `/32` quando o IP
muda e o risco de a regra virar `0.0.0.0/0` "temporariamente".

## Remoção dos recursos da Sprint 3

Executada em **09/11/2026 (UTC)** após a coleta das evidências. Somente os
recursos criados nesta sprint foram removidos, na ordem abaixo, porque a VPC só
pode ser excluída quando não resta nenhuma ENI nela.

1. **Lambdas** (`catalog-backend-api-lambda`, `order-backend-api-lambda`,
   `order-processor-lambda`): desanexadas da VPC e variáveis `DB_*` removidas;
   `DATA_SOURCE=dynamodb` mantido. Nos roles, removido o statement
   `secretsmanager:GetSecretValue` e desanexada a
   `AWSLambdaVPCAccessExecutionRole`.
2. **Bastion**: EC2 terminada; role e instance profile
   `residencia-bastion-ssm-role` e key pair `residencia-bastion-key-pair`
   excluídos, inclusive o `.pem` local.
3. **RDS Proxy** `residencia-marketplace-proxy`, seu endpoint interno, o role
   `residencia-rds-proxy-role` e o log group do proxy.
4. **RDS** `residencia-marketplace-postgres`, sem snapshot final nem backups
   retidos. O secret `rds!db-…`, gerenciado pelo RDS, foi removido junto.
   Excluídos também o subnet group `residencia-marketplace-db-subnets` e o log
   group `RDSOSMetrics`.
5. **VPC endpoints**: Interface (SQS e Secrets Manager) e Gateway (S3 e
   DynamoDB).
6. **Rede**: security groups `residencia-lambda-sg`, `residencia-proxy-sg`,
   `residencia-rds-sg`, `residencia-endpoints-sg` e `residencia-bastion-sg`;
   três subnets; route tables `residencia-private-rt` e `residencia-public-rt`;
   Internet Gateway; e a `residencia-marketplace-vpc`.

A verificação final não encontrou instância, banco, proxy, snapshot, secret,
endpoint, Elastic IP ou VPC remanescente da sprint. O site foi testado após a
remoção e continuou funcionando com DynamoDB.

Permaneceram os recursos da Sprint 2 (Lambdas, DynamoDB, SQS, API Gateway,
Cognito, S3 e CloudFront) e o Quick Setup do SSM, anterior à trilha.
