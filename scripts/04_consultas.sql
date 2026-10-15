-- =============================================================
-- Clínica Médica — Consultas comentadas (T-SQL)
-- =============================================================
USE Clinica;
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;   -- exigido por índices filtrados (o sqlcmd vem com OFF)
GO

-- 1. Pacientes com idade (coluna calculada) e convênio
SELECT p.Nome, p.Idade, ISNULL(c.Nome, N'Particular') AS Convenio
FROM dbo.Paciente p
LEFT JOIN dbo.Convenio c ON c.IdConvenio = p.IdConvenio
ORDER BY p.Idade DESC;

-- 2. Faturamento por especialidade (somente consultas realizadas)
SELECT e.Nome AS Especialidade,
       COUNT(*)                 AS Consultas,
       SUM(c.ValorCobrado)      AS Faturamento,
       AVG(c.ValorCobrado)      AS TicketMedio
FROM dbo.Consulta c
JOIN dbo.Medico m        ON m.IdMedico = c.IdMedico
JOIN dbo.Especialidade e ON e.IdEspecialidade = m.IdEspecialidade
WHERE c.Status = 'REALIZADA'
GROUP BY e.Nome
ORDER BY Faturamento DESC;

-- 3. Taxa de absenteísmo por médico (CASE dentro de agregação)
SELECT m.Nome,
       COUNT(*) AS Agendadas,
       SUM(CASE WHEN c.Status = 'FALTOU' THEN 1 ELSE 0 END) AS Faltas,
       CAST(100.0 * SUM(CASE WHEN c.Status = 'FALTOU' THEN 1 ELSE 0 END) / COUNT(*) AS DECIMAL(5,1)) AS PercFaltas
FROM dbo.Consulta c
JOIN dbo.Medico m ON m.IdMedico = c.IdMedico
GROUP BY m.Nome;

-- 4. Função com valor de tabela: agenda do dia
SELECT * FROM dbo.fn_AgendaDoDia(2, '2026-03-02');

-- 5. Paginação com OFFSET/FETCH (página 2, 3 registros por página)
SELECT IdConsulta, DataHora, Status
FROM dbo.Consulta
ORDER BY DataHora
OFFSET 3 ROWS FETCH NEXT 3 ROWS ONLY;

-- 6. Funções de janela: intervalo entre consultas de cada paciente
SELECT p.Nome, c.DataHora,
       LAG(c.DataHora) OVER (PARTITION BY c.IdPaciente ORDER BY c.DataHora) AS ConsultaAnterior,
       DATEDIFF(DAY,
                LAG(c.DataHora) OVER (PARTITION BY c.IdPaciente ORDER BY c.DataHora),
                c.DataHora) AS DiasDesdeAnterior
FROM dbo.Consulta c
JOIN dbo.Paciente p ON p.IdPaciente = c.IdPaciente
ORDER BY p.Nome, c.DataHora;

-- 7. STRING_AGG (SQL Server 2017+): médicos que atenderam cada paciente
SELECT p.Nome AS Paciente,
       STRING_AGG(m.Nome, N'; ') WITHIN GROUP (ORDER BY m.Nome) AS Medicos
FROM (SELECT DISTINCT IdPaciente, IdMedico FROM dbo.Consulta WHERE Status = 'REALIZADA') x
JOIN dbo.Paciente p ON p.IdPaciente = x.IdPaciente
JOIN dbo.Medico m   ON m.IdMedico   = x.IdMedico
GROUP BY p.Nome;

-- 8. Trilha de auditoria gerada pela trigger
SELECT * FROM dbo.ConsultaAuditoria ORDER BY IdAuditoria;

-- 9. Testando as regras da procedure (cada bloco deve exibir a mensagem de erro)
DECLARE @id INT;
BEGIN TRY
    EXEC dbo.sp_AgendarConsulta 5, 1, '2026-03-16 16:00', @id OUTPUT;   -- horário ocupado
END TRY
BEGIN CATCH
    SELECT ERROR_NUMBER() AS Erro, ERROR_MESSAGE() AS Mensagem;
END CATCH;

BEGIN TRY
    EXEC dbo.sp_AgendarConsulta 5, 1, '2026-03-07 10:00', @id OUTPUT;   -- sábado
END TRY
BEGIN CATCH
    SELECT ERROR_NUMBER() AS Erro, ERROR_MESSAGE() AS Mensagem;
END CATCH;
GO
