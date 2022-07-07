/****** Object:  View [dbo].[V_Aux_Info_Biomaterial_Values] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Aux_Info_Biomaterial_Values]
AS
SELECT T_Cell_Culture.CC_Name AS Biomaterial,
       T_Cell_Culture.CC_ID AS ID,
       T_AuxInfo_Category.Name AS Category,
       T_AuxInfo_Subcategory.Name AS Subcategory,
       T_AuxInfo_Description.Name AS Item,
       T_AuxInfo_Value.VALUE
FROM T_AuxInfo_Category
     INNER JOIN T_AuxInfo_Subcategory
       ON T_AuxInfo_Category.ID = T_AuxInfo_Subcategory.Parent_ID
     INNER JOIN T_AuxInfo_Description
       ON T_AuxInfo_Subcategory.ID = T_AuxInfo_Description.Parent_ID
     INNER JOIN T_AuxInfo_Value
       ON T_AuxInfo_Description.ID = T_AuxInfo_Value.AuxInfo_ID
     INNER JOIN T_Cell_Culture
       ON T_AuxInfo_Value.Target_ID = T_Cell_Culture.CC_ID
WHERE T_AuxInfo_Category.Target_Type_ID = 501


GO
GRANT VIEW DEFINITION ON [dbo].[V_Aux_Info_Biomaterial_Values] TO [DDL_Viewer] AS [dbo]
GO
