-- =============================================================
-- Clínica Médica — Dados de exemplo (fictícios)
-- =============================================================
USE Clinica;
GO
SET NOCOUNT ON;

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;   -- exigido por índices filtrados (o sqlcmd vem com OFF)
GO

INSERT INTO dbo.Especialidade (Nome, ValorConsulta) VALUES
(N'Clínica Geral', 180.00),
(N'Cardiologia',   320.00),
(N'Pediatria',     250.00),
(N'Ortopedia',     300.00);

INSERT INTO dbo.Medico (Nome, CRM, IdEspecialidade) VALUES
(N'Dra. Helena Prado',  'SP-123456', 1),
(N'Dr. Otávio Ramos',   'SP-234567', 2),
(N'Dra. Silvia Campos', 'SP-345678', 3),
(N'Dr. Renato Freitas', 'SP-456789', 4);

INSERT INTO dbo.Convenio (Nome, Desconto) VALUES
(N'Saúde Total', 0.30),
(N'VidaMais',    0.20);

INSERT INTO dbo.Paciente (Nome, CPF, DataNascimento, Telefone, IdConvenio) VALUES
(N'João Batista',     '12345678901', '1958-04-10', '19 99811-0001', 1),
(N'Maria Aparecida',  '23456789012', '1972-09-21', '19 99811-0002', 2),
(N'Gabriel Torres',   '34567890123', '2019-06-15', '19 99811-0003', 1),
(N'Fernanda Lopes',   '45678901234', '1990-12-03', '19 99811-0004', NULL),
(N'Antônio Carlos',   '56789012345', '1965-02-28', '19 99811-0005', NULL);

-- Agendamentos via procedure (todas em dias úteis, horário comercial)
DECLARE @id INT;
EXEC dbo.sp_AgendarConsulta 1, 2, '2026-03-02 09:00', @id OUTPUT;
EXEC dbo.sp_AgendarConsulta 2, 1, '2026-03-02 10:00', @id OUTPUT;
EXEC dbo.sp_AgendarConsulta 3, 3, '2026-03-03 14:00', @id OUTPUT;
EXEC dbo.sp_AgendarConsulta 4, 4, '2026-03-04 08:30', @id OUTPUT;
EXEC dbo.sp_AgendarConsulta 5, 2, '2026-03-05 11:00', @id OUTPUT;
EXEC dbo.sp_AgendarConsulta 1, 1, '2026-03-09 15:00', @id OUTPUT;
EXEC dbo.sp_AgendarConsulta 2, 2, '2026-03-10 09:00', @id OUTPUT;
EXEC dbo.sp_AgendarConsulta 4, 1, '2026-03-16 16:00', @id OUTPUT;
EXEC dbo.sp_AgendarConsulta 3, 3, '2026-03-17 10:00', @id OUTPUT;

-- Atendimentos realizados (o valor cobrado é calculado com o desconto do convênio)
EXEC dbo.sp_RealizarConsulta 1, N'Hipertensão controlada. Retorno em 90 dias.';
EXEC dbo.sp_RealizarConsulta 2, N'Check-up anual.';
EXEC dbo.sp_RealizarConsulta 3, N'Vacinação em dia.';
EXEC dbo.sp_RealizarConsulta 4, N'Entorse leve no tornozelo.';
EXEC dbo.sp_RealizarConsulta 6;

-- Falta e cancelamento (geram registros na auditoria)
UPDATE dbo.Consulta SET Status = 'FALTOU'    WHERE IdConsulta = 5;
UPDATE dbo.Consulta SET Status = 'CANCELADA' WHERE IdConsulta = 7;
GO
