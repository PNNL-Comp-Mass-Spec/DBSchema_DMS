/****** Object:  View [dbo].[V_AuxInfo_Value] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_AuxInfo_Value
AS
SELECT     dbo.T_AuxInfo_Target.Name AS Target, dbo.T_AuxInfo_Value.Target_ID, dbo.T_AuxInfo_Category.Name AS Category, 
                      dbo.T_AuxInfo_Subcategory.Name AS Subcategory, dbo.T_AuxInfo_Description.Name AS Item, dbo.T_AuxInfo_Value.Value, 
                      dbo.T_AuxInfo_Category.Sequence AS SC, dbo.T_AuxInfo_Subcategory.Sequence AS SS, dbo.T_AuxInfo_Description.Sequence AS SI, 
                      dbo.T_AuxInfo_Description.DataSize, dbo.T_AuxInfo_Description.HelperAppend
FROM         dbo.T_AuxInfo_Category INNER JOIN
                      dbo.T_AuxInfo_Subcategory ON dbo.T_AuxInfo_Category.ID = dbo.T_AuxInfo_Subcategory.Parent_ID INNER JOIN
                      dbo.T_AuxInfo_Description ON dbo.T_AuxInfo_Subcategory.ID = dbo.T_AuxInfo_Description.Parent_ID INNER JOIN
                      dbo.T_AuxInfo_Value ON dbo.T_AuxInfo_Description.ID = dbo.T_AuxInfo_Value.AuxInfo_ID INNER JOIN
                      dbo.T_AuxInfo_Target ON dbo.T_AuxInfo_Category.Target_Type_ID = dbo.T_AuxInfo_Target.ID

GO
