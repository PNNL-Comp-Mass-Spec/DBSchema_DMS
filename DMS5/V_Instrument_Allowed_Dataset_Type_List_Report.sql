/****** Object:  View [dbo].[V_Instrument_Allowed_Dataset_Type_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Instrument_Allowed_Dataset_Type_List_Report]
AS
SELECT 'Edit' AS Sel,
       IGADT.IN_Group AS [Instrument Group],
       IGADT.Dataset_Type AS [Dataset Type],
       DTN.DST_Description AS [Type Description],
       IGADT.Comment AS [Usage for This Group]
FROM T_Instrument_Group_Allowed_DS_Type IGADT
     INNER JOIN T_DatasetTypeName DTN
       ON IGADT.Dataset_Type = DTN.DST_name


GO
GRANT VIEW DEFINITION ON [dbo].[V_Instrument_Allowed_Dataset_Type_List_Report] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Instrument_Allowed_Dataset_Type_List_Report] TO [PNL\D3M580] AS [dbo]
GO
