/****** Object:  View [dbo].[V_Instrument_Data_Type_Name_Picklist] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW V_Instrument_Data_Type_Name_Picklist
As
SELECT Raw_Data_Type_ID As ID, Raw_Data_Type_Name As Name
FROM T_Instrument_Data_Type_Name


GO
GRANT VIEW DEFINITION ON [dbo].[V_Instrument_Data_Type_Name_Picklist] TO [DDL_Viewer] AS [dbo]
GO
