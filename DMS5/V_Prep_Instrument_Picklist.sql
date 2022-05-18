/****** Object:  View [dbo].[V_Prep_Instrument_Picklist] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW V_Prep_Instrument_Picklist
As
SELECT Instrument_ID As ID, IN_name As Name
FROM T_Instrument_Name  
WHERE IN_Group = 'PrepHPLC' And IN_status IN ('active', 'offline')


GO
GRANT VIEW DEFINITION ON [dbo].[V_Prep_Instrument_Picklist] TO [DDL_Viewer] AS [dbo]
GO
