/****** Object:  View [dbo].[V_Active_Instrument_Operators] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Active_Instrument_Operators]
As
SELECT Username, 
       Name, 
       Username As [Payroll Num]    -- Deprecated name
FROM dbo.V_Active_Instrument_Users


GO
