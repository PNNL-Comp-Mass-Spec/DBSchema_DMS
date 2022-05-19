/****** Object:  View [dbo].[V_EMSL_Instrument_Usage_Type_Picklist] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW V_EMSL_Instrument_Usage_Type_Picklist
As
SELECT ID, Name, Description
FROM T_EMSL_Instrument_Usage_Type
WHERE Enabled > 0


GO
GRANT VIEW DEFINITION ON [dbo].[V_EMSL_Instrument_Usage_Type_Picklist] TO [DDL_Viewer] AS [dbo]
GO
