# Residência, Trilha Foundation

Repositório evolutivo da Trilha Foundation da Residência DevOps na Nuvem. O
mesmo projeto acompanha o aluno durante as 12 sprints e recebe novas capacidades
sem descartar o que já foi construído.

## Estrutura do repositório

```text
residencia-trilha-foundation/
├── .env.example                       # modelo das variáveis locais; copie para .env
├── scripts/
│   ├── deploy.sh                      # build, sync no S3 e invalidação do CloudFront
│   └── tests/cdn_load/test.sh         # mede X-Cache na URL publicada
├── site/                              # SPA React e TypeScript
├── backend/
│   └── lambdas/
│       ├── 01-catalog-backend-api-lambda/
│       ├── 02-order-backend-api-lambda/
│       └── 03-order-processor-lambda/
└── infrastructure/
    ├── bootstrap.sh                   # aplica um profile
    ├── cloudformation/
    │   ├── web-edge.yaml              # a borda da Sprint 1, descrita em CloudFormation
    │   └── scripts/create-web-edge-changeset.sh
    ├── foundation/terraform-state/    # reservado para o remote state
    ├── profiles/                      # ponto inicial de cada sprint
    └── stacks/                        # root stacks Terraform evolutivas
        ├── 01-web-edge/
        ├── 02-identity/
        ├── 03-marketplace-api/
        ├── 04-database/
        ├── 05-container-platform/
        └── 06-gitops/
```

Os diretórios em `infrastructure/stacks` serão root stacks independentes, no
mesmo padrão da Trilha Professional. Eles ainda não possuem arquivos `.tf`.
O template em `infrastructure/cloudformation/` é o exercício opcional da
Sprint 1: a mesma borda, descrita para a AWS guardar o estado na stack. Ele
não substitui as stacks Terraform, que começam na Sprint 5.

## Como as sprints, as stacks e o state se relacionam

Não existe uma cópia da infraestrutura para cada sprint. Cada diretório em
`infrastructure/stacks` representa uma responsabilidade e evolui no mesmo lugar
ao longo da trilha. Por exemplo, `01-web-edge` continuará sendo a stack de S3,
CloudFront, ACM e Route 53 quando novas capacidades forem adicionadas.

Existem três conceitos diferentes:

- a tag do Git determina a versão do código disponível naquele ponto da trilha;
- o profile determina quais stacks formam o ambiente inicial de uma sprint;
- o state continua independente por stack e acompanha a evolução do ambiente.

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

### Evolução normal do ambiente

No avanço entre sprints, as mesmas stacks e os mesmos states são utilizados. O
Terraform compara a nova versão do código com a infraestrutura existente e faz
somente as alterações necessárias. As chaves seguirão este padrão:

```text
residencia-foundation/01-web-edge.tfstate
residencia-foundation/02-identity.tfstate
residencia-foundation/03-marketplace-api.tfstate
```

Os profiles `ready-for-sprint-01` até `ready-for-sprint-12`, mais o
`complete`, reproduzem o ambiente ao final da sprint anterior. Um profile
seleciona stacks; ele não cria outra versão da stack nem outro state.

As cinco primeiras sprints são feitas pelo Console da AWS, então os profiles
`ready-for-sprint-01` até `ready-for-sprint-05` não selecionam nenhuma stack.

### Voltar para uma sprint anterior

Fazer apenas o checkout de uma tag antiga não altera a conta AWS. Aplicar código
antigo contra um ambiente mais novo pode remover recursos ou deixar stacks de
sprints posteriores ainda provisionadas.

Para voltar de verdade, existe um ambiente ativo por vez. Primeiro, destrua o
ambiente usando a versão e o profile atuais. Depois, faça checkout da tag
desejada e aplique o profile correspondente:

```bash
./infrastructure/bootstrap.sh destroy ready-for-sprint-06
git checkout start-sprint-05
./infrastructure/bootstrap.sh apply ready-for-sprint-05
```

Manter duas sprints provisionadas simultaneamente exigiria states e nomes de
recursos isolados. Esse cenário não faz parte do fluxo padrão, para manter a
experiência do aluno simples.

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

Na Sprint 1, o site usa autenticação mock:

```env
VITE_AUTH_MODE=mock
```

O formulário aceita qualquer e-mail válido e uma senha com pelo menos seis
caracteres. O código do primeiro acesso e da recuperação de senha já está
preparado para o Amazon Cognito.

Na Sprint 2, nenhuma mudança no código do frontend é necessária. Basta informar:

```env
VITE_AUTH_MODE=cognito
VITE_AWS_REGION=us-east-1
VITE_COGNITO_USER_POOL_ID=us-east-1_xxxxxxxxx
VITE_COGNITO_CLIENT_ID=xxxxxxxxxxxxxxxxxxxxxxxxxx
VITE_API_URL=https://xxxxxxxxxx.execute-api.us-east-1.amazonaws.com
```

## Backend da Sprint 2

O código das três Lambdas já está pronto. O trabalho do aluno é empacotar,
publicar e conectar os recursos pelo Console da AWS.

| Lambda | Runtime | Responsabilidade |
| --- | --- | --- |
| `catalog-backend-api-lambda` | TypeScript (Node.js 22) | Consultar e cadastrar produtos e gerar upload opcional de imagem |
| `order-backend-api-lambda` | .NET | Consultar pedidos do seller e publicar novas compras na SQS |
| `order-processor-lambda` | TypeScript (Node.js 22) | Consumir a SQS e processar o pedido de forma assíncrona |

As Lambdas iniciam com `DATA_SOURCE=mock`. Os adapters para RDS já estão
separados e serão ativados na Sprint 3 com `DATA_SOURCE=rds` e as variáveis de
conexão. Nenhuma mudança na regra de negócio ou nos handlers será necessária.

Consulte [backend/README.md](backend/README.md) para conhecer os packages, os
handlers e as variáveis de ambiente.

## Variáveis locais

```bash
cp .env.example .env
```

O `.env` fica de fora do Git. `scripts/deploy.sh` e
`infrastructure/cloudformation/scripts/create-web-edge-changeset.sh` leem esse
arquivo.

| Variável | Quem usa | Função |
| --- | --- | --- |
| `BUCKET_NAME` | deploy e o change set | Bucket que recebe `site/dist` |
| `DISTRIBUTION_ID` | deploy | Distribuição que a invalidação deve limpar |
| `DOMAIN_NAME` | change set | Nome publicado pela distribuição nova |
| `DNS_NAME` | change set | Zona Route 53 em que o script busca o hosted zone id |
| `STACK_NAME` | change set | Nome da stack. O padrão está no `.env.example` |
| `AWS_PROFILE` | change set | Perfil da AWS CLI |
| `AWS_REGION` | change set | Tem de ser `us-east-1`: o CloudFront só aceita certificado ACM dessa região |

O `.env.example` do `site/` é outro arquivo. Ele guarda `VITE_AUTH_MODE` e as
variáveis do Cognito, usadas pelo frontend, não pelos scripts de publicação.

## Publicar o site

```bash
./scripts/deploy.sh
```

O script gera o build em `site/dist`, envia o conteúdo com
`aws s3 sync --delete` para `BUCKET_NAME` e pede a invalidação de `/` e
`/index.html`. O comando termina quando o CloudFront aceita o pedido. A
invalidação em si continua por alguns minutos.

`DISTRIBUTION_ID` é o da distribuição que já serve o site. Se a publicação for
para uma stack CloudFormation nova, troque esse valor pela saída `DistributionId`
dessa stack antes de rodar o deploy.

Para ver o cache na borda:

```bash
./scripts/tests/cdn_load/test.sh
```

O teste repete o pedido de `index.html` e de um asset com hash e imprime
`X-Cache`, `Age` e o tempo de cada resposta. A URL está escrita no script.

## CloudFormation da borda

`infrastructure/cloudformation/web-edge.yaml` descreve bucket privado, origin
access control, certificado, distribuição e os alias de DNS. Use um bucket e
um domínio que ainda não pertençam à distribuição criada no console. Um nome
só pode estar em uma distribuição.

```bash
./infrastructure/cloudformation/scripts/create-web-edge-changeset.sh
```

O script lê `DOMAIN_NAME`, `DNS_NAME` e `BUCKET_NAME` do `.env`, busca o id da
cache policy `Managed-CachingOptimized` e o hosted zone id de `DNS_NAME`, e
cria o change set. Ele não executa. Revise os recursos no console e só então:

```bash
aws cloudformation execute-change-set \
  --stack-name "$STACK_NAME" \
  --change-set-name NOME_IMPRESSO_PELO_SCRIPT \
  --region us-east-1 \
  --profile "$AWS_PROFILE"
```

Apagar a stack remove a distribuição, o certificado e os registros de DNS. O
bucket permanece: o template marca esse recurso para retenção, então esvazie e
apague o bucket à parte quando o exercício acabar.
