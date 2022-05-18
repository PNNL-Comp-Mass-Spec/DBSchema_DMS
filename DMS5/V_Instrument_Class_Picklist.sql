/****** Object:  View [dbo].[V_Instrument_Class_Picklist] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW V_Instrument_Class_Picklist
As
SELECT IN_Class As Name, Comment As Description
FROM T_Instrument_Class 


GO
GRANT VIEW DEFINITION ON [dbo].[V_Instrument_Class_Picklist] TO [DDL_Viewer] AS [dbo]
GO
