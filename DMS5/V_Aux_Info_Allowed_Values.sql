/****** Object:  View [dbo].[V_Aux_Info_Allowed_Values] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW dbo.V_Aux_Info_Allowed_Values
AS
SELECT dbo.T_AuxInfo_Target.Name AS Target, 
   dbo.T_AuxInfo_Category.Name AS Category, 
   dbo.T_AuxInfo_Subcategory.Name AS Subcategory, 
   dbo.T_AuxInfo_Description.Name AS Item, 
   dbo.T_AuxInfo_Allowed_Values.Value AS AllowedValue
FROM dbo.T_AuxInfo_Category INNER JOIN
   dbo.T_AuxInfo_Subcategory ON 
   dbo.T_AuxInfo_Category.ID = dbo.T_AuxInfo_Subcategory.Parent_ID
    INNER JOIN
   dbo.T_AuxInfo_Description ON 
   dbo.T_AuxInfo_Subcategory.ID = dbo.T_AuxInfo_Description.Parent_ID
    INNER JOIN
   dbo.T_AuxInfo_Target ON 
   dbo.T_AuxInfo_Category.Target_Type_ID = dbo.T_AuxInfo_Target.ID
    INNER JOIN
   dbo.T_AuxInfo_Allowed_Values ON 
   dbo.T_AuxInfo_Description.ID = dbo.T_AuxInfo_Allowed_Values.AuxInfoID
GO
GRANT VIEW DEFINITION ON [dbo].[V_Aux_Info_Allowed_Values] TO [PNL\D3M578] AS [dbo]
GO
