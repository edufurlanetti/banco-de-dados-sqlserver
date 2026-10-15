-- =============================================================
-- Clínica Médica — Procedures, funções e trigger (T-SQL)
-- =============================================================
USE Clinica;
GO

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;   -- exigido por índices filtrados (o sqlcmd vem com OFF)
GO

-- Função escalar: valor da consulta com desconto do convênio
CREATE OR ALTER FUNCTION dbo.fn_ValorConsulta (@IdMedico INT, @IdPaciente INT)
RETURNS DECIMAL(10,2)
AS
BEGIN
    DECLARE @Valor DECIMAL(10,2);

    SELECT @Valor = e.ValorConsulta * (1 - ISNULL(c.Desconto, 0))
    FROM dbo.Medico m
    JOIN dbo.Especialidade e ON e.IdEspecialidade = m.IdEspecialidade
    CROSS JOIN dbo.Paciente p
    LEFT JOIN dbo.Convenio c ON c.IdConvenio = p.IdConvenio
    WHERE m.IdMedico = @IdMedico AND p.IdPaciente = @IdPaciente;

    RETURN @Valor;
END;
GO

-- Função com valor de tabela: agenda de um médico em um dia
CREATE OR ALTER FUNCTION dbo.fn_AgendaDoDia (@IdMedico INT, @Dia DATE)
RETURNS TABLE
AS
RETURN
(
    SELECT c.IdConsulta, CONVERT(CHAR(5), c.DataHora, 108) AS Horario,
           p.Nome AS Paciente, c.Status
    FROM dbo.Consulta c
    JOIN dbo.Paciente p ON p.IdPaciente = c.IdPaciente
    WHERE c.IdMedico = @IdMedico
      AND c.DataHora >= @Dia
      AND c.DataHora <  DATEADD(DAY, 1, @Dia)
);
GO

-- Procedure: agendamento com validações e tratamento de erro
CREATE OR ALTER PROCEDURE dbo.sp_AgendarConsulta
    @IdPaciente INT,
    @IdMedico   INT,
    @DataHora   DATETIME2(0),
    @IdConsulta INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM dbo.Medico WHERE IdMedico = @IdMedico AND Ativo = 1)
            THROW 50001, N'Médico inexistente ou inativo.', 1;

        IF DATEPART(HOUR, @DataHora) NOT BETWEEN 8 AND 17
            THROW 50002, N'Horário fora do expediente (08h às 18h).', 1;

        IF DATEPART(WEEKDAY, @DataHora) IN (1, 7)   -- com DATEFIRST padrão (7): domingo = 1, sábado = 7
            THROW 50003, N'A clínica não atende aos fins de semana.', 1;

        BEGIN TRANSACTION;
            INSERT INTO dbo.Consulta (IdPaciente, IdMedico, DataHora)
            VALUES (@IdPaciente, @IdMedico, @DataHora);

            SET @IdConsulta = SCOPE_IDENTITY();
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

        IF ERROR_NUMBER() IN (2601, 2627)            -- violação do índice único
            THROW 50004, N'O médico já possui consulta nesse horário.', 1;

        THROW;                                       -- repassa qualquer outro erro
    END CATCH
END;
GO

-- Procedure: finaliza a consulta e registra o valor cobrado
CREATE OR ALTER PROCEDURE dbo.sp_RealizarConsulta
    @IdConsulta  INT,
    @Observacoes NVARCHAR(500) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE c
       SET Status       = 'REALIZADA',
           ValorCobrado = dbo.fn_ValorConsulta(c.IdMedico, c.IdPaciente),
           Observacoes  = @Observacoes
    FROM dbo.Consulta c
    WHERE c.IdConsulta = @IdConsulta AND c.Status = 'AGENDADA';

    IF @@ROWCOUNT = 0
        THROW 50005, N'Consulta não encontrada ou não está agendada.', 1;
END;
GO

-- Tabela de auditoria + trigger AFTER UPDATE (usa as tabelas virtuais inserted/deleted)
CREATE TABLE dbo.ConsultaAuditoria (
    IdAuditoria    INT IDENTITY(1,1) PRIMARY KEY,
    IdConsulta     INT          NOT NULL,
    StatusAnterior VARCHAR(12)  NOT NULL,
    StatusNovo     VARCHAR(12)  NOT NULL,
    Usuario        NVARCHAR(128) NOT NULL DEFAULT SUSER_SNAME(),
    DataAlteracao  DATETIME2(0) NOT NULL DEFAULT SYSDATETIME()
);
GO

CREATE OR ALTER TRIGGER dbo.trg_Consulta_AuditaStatus
ON dbo.Consulta
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO dbo.ConsultaAuditoria (IdConsulta, StatusAnterior, StatusNovo)
    SELECT i.IdConsulta, d.Status, i.Status
    FROM inserted i
    JOIN deleted  d ON d.IdConsulta = i.IdConsulta
    WHERE i.Status <> d.Status;
END;
GO
