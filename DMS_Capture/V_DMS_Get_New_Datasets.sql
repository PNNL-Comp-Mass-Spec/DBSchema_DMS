/****** Object:  View [dbo].[V_DMS_Get_New_Datasets] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_DMS_Get_New_Datasets] as
SELECT DS.Dataset_Num AS Dataset,
       DS.Dataset_ID,
       TIN.IN_name AS Instrument,
       TIN.IN_class AS Instrument_Class,
       TIN.IN_Group AS Instrument_Group
FROM S_DMS_T_Dataset AS DS
     INNER JOIN S_DMS_T_Instrument_Name AS TIN
       ON DS.DS_instrument_name_ID = TIN.Instrument_ID
WHERE (DS_state_ID = 1)
 

GO
GRANT VIEW DEFINITION ON [dbo].[V_DMS_Get_New_Datasets] TO [DDL_Viewer] AS [dbo]
GO
