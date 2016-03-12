/****** Object:  View [dbo].[V_Aux_Info_Definition_wID] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW dbo.V_Aux_Info_Definition_wID
AS
SELECT TOP 100 PERCENT dbo.T_AuxInfo_Target.Name AS Target, 
   dbo.T_AuxInfo_Category.Target_Type_ID AS TargT_ID, 
   dbo.T_AuxInfo_Category.Name AS Category, 
   dbo.T_AuxInfo_Category.ID AS Cat_ID, 
   dbo.T_AuxInfo_Subcategory.Name AS Subcategory, 
   dbo.T_AuxInfo_Subcategory.ID AS Sub_ID, 
   dbo.T_AuxInfo_Description.Name AS Item, 
   dbo.T_AuxInfo_Description.ID AS Item_ID, 
   dbo.T_AuxInfo_Category.Sequence AS Cat_Seq, 
   dbo.T_AuxInfo_Subcategory.Sequence AS Sub_Seq, 
   dbo.T_AuxInfo_Description.Sequence AS Item_Seq, 
   dbo.T_AuxInfo_Description.DataSize, 
   dbo.T_AuxInfo_Description.HelperAppend
FROM dbo.T_AuxInfo_Category INNER JOIN
   dbo.T_AuxInfo_Subcategory ON 
   dbo.T_AuxInfo_Category.ID = dbo.T_AuxInfo_Subcategory.Parent_ID
    INNER JOIN
   dbo.T_AuxInfo_Description ON 
   dbo.T_AuxInfo_Subcategory.ID = dbo.T_AuxInfo_Description.Parent_ID
    INNER JOIN
   dbo.T_AuxInfo_Target ON 
   dbo.T_AuxInfo_Category.Target_Type_ID = dbo.T_AuxInfo_Target.ID
GO
GRANT VIEW DEFINITION ON [dbo].[V_Aux_Info_Definition_wID] TO [PNL\D3M578] AS [dbo]
GO
