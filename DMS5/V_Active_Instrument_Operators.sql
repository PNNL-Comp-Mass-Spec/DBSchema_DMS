/****** Object:  View [dbo].[V_Active_Instrument_Operators] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Active_Instrument_Operators]
As
SELECT [Payroll Num], [Name]
FROM dbo.V_Active_Instrument_Users


GO
