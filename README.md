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
