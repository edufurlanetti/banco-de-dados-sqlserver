-- Soluções — Clínica Médica (SQL Server)
USE Clinica;
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;   -- exigido por índices filtrados (o sqlcmd vem com OFF)
GO

-- 1
SELECT p.Nome AS Paciente, m.Nome AS Medico, e.Nome AS Especialidade,
       FORMAT(c.DataHora, 'dd/MM/yyyy HH:mm') AS DataHora
FROM dbo.Consulta c
JOIN dbo.Paciente p      ON p.IdPaciente = c.IdPaciente
JOIN dbo.Medico m        ON m.IdMedico = c.IdMedico
JOIN dbo.Especialidade e ON e.IdEspecialidade = m.IdEspecialidade
WHERE c.Status = 'AGENDADA'
ORDER BY c.DataHora;

-- 2
SELECT ISNULL(cv.Nome, N'Particular') AS Convenio, SUM(c.ValorCobrado) AS Faturamento
FROM dbo.Consulta c
JOIN dbo.Paciente p      ON p.IdPaciente = c.IdPaciente
LEFT JOIN dbo.Convenio cv ON cv.IdConvenio = p.IdConvenio
WHERE c.Status = 'REALIZADA'
GROUP BY ISNULL(cv.Nome, N'Particular');

-- 3
SELECT p.Nome
FROM dbo.Paciente p
WHERE NOT EXISTS (SELECT 1 FROM dbo.Consulta c
                  WHERE c.IdPaciente = p.IdPaciente AND c.Status = 'FALTOU');

-- 4
GO
CREATE OR ALTER VIEW dbo.vw_ProntuarioResumido AS
SELECT p.Nome AS Paciente, c.DataHora, m.Nome AS Medico, c.Observacoes
FROM dbo.Consulta c
JOIN dbo.Paciente p ON p.IdPaciente = c.IdPaciente
JOIN dbo.Medico m   ON m.IdMedico   = c.IdMedico
WHERE c.Status = 'REALIZADA';
GO

SELECT * FROM dbo.vw_ProntuarioResumido ORDER BY Paciente, DataHora;

-- 5
GO
CREATE OR ALTER PROCEDURE dbo.sp_CancelarConsulta @IdConsulta INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @DataHora DATETIME2(0);
    SELECT @DataHora = DataHora FROM dbo.Consulta
    WHERE IdConsulta = @IdConsulta AND Status = 'AGENDADA';

    IF @DataHora IS NULL
        THROW 50010, N'Consulta inexistente ou não agendada.', 1;

    IF DATEDIFF(HOUR, SYSDATETIME(), @DataHora) < 24
        THROW 50011, N'Cancelamento permitido somente com 24 horas de antecedência.', 1;

    UPDATE dbo.Consulta SET Status = 'CANCELADA' WHERE IdConsulta = @IdConsulta;
END;
GO

-- 6
CREATE TABLE #NovosValores (Nome NVARCHAR(60), Valor DECIMAL(10,2));
INSERT INTO #NovosValores VALUES
(N'Cardiologia', 350.00),
(N'Dermatologia', 280.00);

MERGE dbo.Especialidade AS destino
USING #NovosValores AS origem
   ON destino.Nome = origem.Nome
WHEN MATCHED THEN
    UPDATE SET ValorConsulta = origem.Valor
WHEN NOT MATCHED BY TARGET THEN
    INSERT (Nome, ValorConsulta) VALUES (origem.Nome, origem.Valor);

SELECT * FROM dbo.Especialidade;
DROP TABLE #NovosValores;

-- 7
-- Com XACT_ABORT ON, qualquer erro em tempo de execução encerra e desfaz
-- automaticamente a transação inteira. Sem ele, alguns erros abortam só o
-- comando que falhou e a transação poderia ficar aberta e parcialmente
-- aplicada, prendendo bloqueios até alguém executar COMMIT ou ROLLBACK.
