/****** Object:  View [dbo].[V_Aux_Info_Definition] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Aux_Info_Definition]
AS
SELECT Category_Target.[Name] AS Target,
       Category.[Name] AS Category,
       Subcategory.[Name] AS Subcategory,
       Item.[Name] AS Item,
       Item.ID AS Item_ID,
       Category.[Sequence] AS SC,
       Subcategory.[Sequence] AS SS,
       Item.[Sequence] AS SI,
       Item.DataSize,
       Item.HelperAppend
FROM T_AuxInfo_Category Category
     INNER JOIN T_AuxInfo_Subcategory Subcategory
       ON Category.ID = Subcategory.Parent_ID
     INNER JOIN T_AuxInfo_Description Item
       ON Subcategory.ID = Item.Parent_ID
     INNER JOIN T_AuxInfo_Target Category_Target
       ON Category.Target_Type_ID = Category_Target.ID
WHERE (Item.Active = 'Y')


GO
GRANT VIEW DEFINITION ON [dbo].[V_Aux_Info_Definition] TO [DDL_Viewer] AS [dbo]
GO
