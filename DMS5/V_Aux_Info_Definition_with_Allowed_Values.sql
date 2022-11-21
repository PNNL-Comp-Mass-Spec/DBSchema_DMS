/****** Object:  View [dbo].[V_Aux_Info_Definition_with_Allowed_Values] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Aux_Info_Definition_with_Allowed_Values]
AS
SELECT Category_Target.Target_Type_Name AS Target,
       Category.Aux_Category AS Category,
       Subcategory.Aux_Subcategory AS Subcategory,
       Item.Aux_Description AS Item,
       Item.Aux_Description_ID AS Item_ID,
       dbo.GetAuxInfoAllowedValues(Item.Aux_Description_ID) AS Allowed_Values,
       Category.[Sequence] AS SC,
       Subcategory.[Sequence] AS SS,
       Item.[Sequence] AS SI,
       Item.DataSize,
       Item.HelperAppend
FROM T_Aux_Info_Category Category
     INNER JOIN T_Aux_Info_Subcategory Subcategory
       ON Category.Aux_Category_ID = Subcategory.Aux_Category_ID
     INNER JOIN T_Aux_Info_Description Item
       ON Subcategory.Aux_Subcategory_ID = Item.Aux_Subcategory_ID
     INNER JOIN T_Aux_Info_Target Category_Target
       ON Category.Target_Type_ID = Category_Target.Target_Type_ID
WHERE Item.Active = 'Y'


GO
