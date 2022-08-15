/****** Object:  View [dbo].[V_Aux_Info_Definition_with_Allowed_Values] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Aux_Info_Definition_with_Allowed_Values]
AS
SELECT Category_Target.[Name] AS Target,
       Category.[Name] AS Category,
       Subcategory.[Name] AS Subcategory,
       Item.[Name] AS Item,
       Item.ID AS Item_ID,
       dbo.GetAuxInfoAllowedValues(Item.ID) AS Allowed_Values,
       Category.[Sequence] AS SC,
       Subcategory.[Sequence] AS SS,
       Item.[Sequence] AS SI,
       Item.DataSize,
       Item.HelperAppend
FROM T_AuxInfo_Category Category
     INNER JOIN T_AuxInfo_Subcategory Subcategory
       ON Category.ID = Subcategory.Aux_Category_ID
     INNER JOIN T_AuxInfo_Description Item
       ON Subcategory.ID = Item.Aux_Subcategory_ID
     INNER JOIN T_AuxInfo_Target Category_Target
       ON Category.Target_Type_ID = Category_Target.ID
WHERE Item.Active = 'Y'


GO
