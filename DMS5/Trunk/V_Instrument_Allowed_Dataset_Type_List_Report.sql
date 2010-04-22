/****** Object:  View [dbo].[V_Instrument_Allowed_Dataset_Type_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Instrument_Allowed_Dataset_Type_List_Report
AS
SELECT     'Edit' AS Sel, IADT.Instrument, IADT.Dataset_Type AS [Dataset Type], DTN.DST_Description AS [Type Description], 
                      IADT.Comment AS [Usage For This Instrument]
FROM         dbo.T_Instrument_Allowed_Dataset_Type AS IADT INNER JOIN
                      dbo.T_DatasetTypeName AS DTN ON IADT.Dataset_Type = DTN.DST_Name INNER JOIN
                      dbo.T_Instrument_Name ON IADT.Instrument = dbo.T_Instrument_Name.IN_name

GO
GRANT VIEW DEFINITION ON [dbo].[V_Instrument_Allowed_Dataset_Type_List_Report] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Instrument_Allowed_Dataset_Type_List_Report] TO [PNL\D3M580] AS [dbo]
GO
