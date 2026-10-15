# Banco de Dados com SQL Server — Clínica Médica

Sistema de **agendamento de consultas** de uma clínica médica em **Microsoft SQL Server** com **T-SQL**: procedures com tratamento de erros, funções escalares e de tabela, *trigger* de auditoria, colunas calculadas e índice filtrado.

> Material das disciplinas de Banco de Dados e Desenvolvimento Web com .NET — Prof. Eduardo Furlanetti.

## Estudo de caso

```mermaid
erDiagram
    ESPECIALIDADE ||--o{ MEDICO   : agrupa
    MEDICO        ||--o{ CONSULTA : atende
    PACIENTE      ||--o{ CONSULTA : agenda
    CONVENIO      ||--o{ PACIENTE : cobre
    CONSULTA      ||--o{ CONSULTA_AUDITORIA : "tem histórico"
```

Regras de negócio:

- Um médico **não pode ter duas consultas ativas no mesmo horário** (índice único filtrado).
- Agendamentos só em **dias úteis, das 8h às 18h**, e somente com médicos ativos.
- O **valor cobrado** aplica o desconto do convênio do paciente.
- Toda mudança de status é **auditada** por *trigger*, que registra usuário e data.

## Recursos de T-SQL explorados

| Recurso | Arquivo |
|---|---|
| `IDENTITY`, `CONSTRAINT` nomeadas, coluna calculada, índice filtrado e `INCLUDE` | `01_schema.sql` |
| `CREATE OR ALTER`, `TRY...CATCH`, `THROW`, `XACT_ABORT`, parâmetro `OUTPUT` | `02_programacao.sql` |
| Função escalar e função com valor de tabela (*inline TVF*) | `02_programacao.sql` |
| *Trigger* `AFTER UPDATE` com `inserted`/`deleted` | `02_programacao.sql` |
| `OFFSET/FETCH`, `LAG`, `STRING_AGG ... WITHIN GROUP`, `MERGE`, `FORMAT` | `04_consultas.sql`, `exercicios/` |

## Como executar

### Docker

```bash
docker compose up -d
```

Aguarde cerca de 20 segundos e carregue os scripts na ordem (a opção `-C` aceita o certificado autoassinado do contêiner):

```bash
for f in 01_schema 02_programacao 03_dados 04_consultas; do
  docker exec clinica-sqlserver /opt/mssql-tools18/bin/sqlcmd \
    -S localhost -U sa -P 'Senha@Forte123' -C -i /scripts/$f.sql
done
```

No Windows (PowerShell), execute um arquivo por vez trocando `$f` pelo nome do script.

### SQL Server Management Studio, Azure Data Studio ou VS Code

Conecte em `localhost,1433` com o usuário `sa` e a senha acima, abra os scripts e execute-os na ordem `01` → `04`.

## Estrutura

```
scripts/
├── 01_schema.sql        # banco, tabelas, restrições e índices
├── 02_programacao.sql   # funções, procedures e trigger
├── 03_dados.sql         # dados de exemplo (via procedures)
└── 04_consultas.sql     # consultas comentadas e testes das regras
exercicios/
├── lista.md
└── solucoes.sql
```

## Licença

[MIT](LICENSE)
