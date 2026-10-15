# Lista de exercícios — Clínica Médica (SQL Server)

Execute antes os scripts `01` a `03` da pasta `scripts/`.

1. Liste as consultas agendadas (ainda não realizadas) com paciente, médico, especialidade e data formatada como `dd/MM/yyyy HH:mm` (use `FORMAT`).
2. Mostre o faturamento por convênio, incluindo os pacientes particulares como `Particular`.
3. Quais pacientes nunca faltaram a uma consulta?
4. Crie a *view* `vw_ProntuarioResumido` com paciente, data, médico e observações das consultas realizadas.
5. Crie a procedure `sp_CancelarConsulta @IdConsulta` que só permita cancelar consultas com pelo menos 24 horas de antecedência em relação a `SYSDATETIME()`.
6. Usando `MERGE`, atualize os valores das especialidades a partir de uma tabela temporária `#NovosValores (Nome, Valor)`, inserindo especialidades novas.
7. Explique por que a procedure de agendamento usa `SET XACT_ABORT ON`.

As soluções estão em [`solucoes.sql`](solucoes.sql).
