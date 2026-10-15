-- =============================================================
-- Clínica Médica — Modelo físico (SQL Server 2019+ / T-SQL)
-- Autor: Prof. Eduardo Furlanetti
-- =============================================================

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;   -- exigido por índices filtrados (o sqlcmd vem com OFF)
GO

USE master;
GO

IF DB_ID(N'Clinica') IS NOT NULL
BEGIN
    ALTER DATABASE Clinica SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE Clinica;
END
GO

CREATE DATABASE Clinica COLLATE Latin1_General_CI_AI;
GO

USE Clinica;
GO

CREATE TABLE dbo.Especialidade (
    IdEspecialidade INT IDENTITY(1,1) CONSTRAINT PK_Especialidade PRIMARY KEY,
    Nome            NVARCHAR(60) NOT NULL CONSTRAINT UQ_Especialidade_Nome UNIQUE,
    ValorConsulta   DECIMAL(10,2) NOT NULL CONSTRAINT CK_Especialidade_Valor CHECK (ValorConsulta > 0)
);

CREATE TABLE dbo.Medico (
    IdMedico        INT IDENTITY(1,1) CONSTRAINT PK_Medico PRIMARY KEY,
    Nome            NVARCHAR(100) NOT NULL,
    CRM             VARCHAR(12)   NOT NULL CONSTRAINT UQ_Medico_CRM UNIQUE,
    IdEspecialidade INT           NOT NULL
        CONSTRAINT FK_Medico_Especialidade REFERENCES dbo.Especialidade (IdEspecialidade),
    Ativo           BIT           NOT NULL CONSTRAINT DF_Medico_Ativo DEFAULT (1)
);

CREATE TABLE dbo.Convenio (
    IdConvenio  INT IDENTITY(1,1) CONSTRAINT PK_Convenio PRIMARY KEY,
    Nome        NVARCHAR(60)  NOT NULL CONSTRAINT UQ_Convenio_Nome UNIQUE,
    Desconto    DECIMAL(4,2)  NOT NULL                     -- 0.30 = 30%
        CONSTRAINT CK_Convenio_Desconto CHECK (Desconto BETWEEN 0 AND 1)
);

CREATE TABLE dbo.Paciente (
    IdPaciente     INT IDENTITY(1,1) CONSTRAINT PK_Paciente PRIMARY KEY,
    Nome           NVARCHAR(100) NOT NULL,
    CPF            CHAR(11)      NOT NULL CONSTRAINT UQ_Paciente_CPF UNIQUE,
    DataNascimento DATE          NOT NULL,
    Telefone       VARCHAR(15)   NULL,
    IdConvenio     INT           NULL
        CONSTRAINT FK_Paciente_Convenio REFERENCES dbo.Convenio (IdConvenio),
    -- Coluna calculada (não persistida): idade aproximada em anos
    Idade AS (DATEDIFF(YEAR, DataNascimento, GETDATE())
              - CASE WHEN DATEADD(YEAR, DATEDIFF(YEAR, DataNascimento, GETDATE()), DataNascimento) > GETDATE()
                     THEN 1 ELSE 0 END)
);

CREATE TABLE dbo.Consulta (
    IdConsulta  INT IDENTITY(1,1) CONSTRAINT PK_Consulta PRIMARY KEY,
    IdPaciente  INT          NOT NULL CONSTRAINT FK_Consulta_Paciente REFERENCES dbo.Paciente (IdPaciente),
    IdMedico    INT          NOT NULL CONSTRAINT FK_Consulta_Medico   REFERENCES dbo.Medico (IdMedico),
    DataHora    DATETIME2(0) NOT NULL,
    Status      VARCHAR(12)  NOT NULL CONSTRAINT DF_Consulta_Status DEFAULT ('AGENDADA')
        CONSTRAINT CK_Consulta_Status CHECK (Status IN ('AGENDADA','REALIZADA','CANCELADA','FALTOU')),
    ValorCobrado DECIMAL(10,2) NULL,
    Observacoes NVARCHAR(500) NULL
);

-- Índice filtrado: um médico não pode ter duas consultas ativas no mesmo horário
CREATE UNIQUE INDEX UX_Consulta_Medico_Horario
    ON dbo.Consulta (IdMedico, DataHora)
    WHERE Status IN ('AGENDADA', 'REALIZADA');

CREATE INDEX IX_Consulta_Paciente ON dbo.Consulta (IdPaciente) INCLUDE (DataHora, Status);
GO
