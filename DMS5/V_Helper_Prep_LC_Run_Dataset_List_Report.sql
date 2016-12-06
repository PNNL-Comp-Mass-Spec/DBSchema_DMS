/****** Object:  View [dbo].[V_Helper_Prep_LC_Run_Dataset_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/* */
CREATE VIEW dbo.V_Helper_Prep_LC_Run_Dataset_List_Report
AS
SELECT     dbo.T_Dataset.Dataset_ID AS ID, 'x' AS Sel, dbo.T_Dataset.Dataset_Num AS Dataset, dbo.T_Instrument_Name.IN_name AS Instrument, 
                      dbo.T_Dataset.DS_comment AS Comment
FROM         dbo.T_Dataset INNER JOIN
                      dbo.T_Instrument_Name ON dbo.T_Dataset.DS_instrument_name_ID = dbo.T_Instrument_Name.Instrument_ID
WHERE     (NOT (dbo.T_Dataset.Dataset_ID IN
                          (SELECT     Dataset_ID
                            FROM          dbo.T_Prep_LC_Run_Dataset))) AND (dbo.T_Dataset.DS_type_ID = 31)

GO
GRANT VIEW DEFINITION ON [dbo].[V_Helper_Prep_LC_Run_Dataset_List_Report] TO [DDL_Viewer] AS [dbo]
GO
