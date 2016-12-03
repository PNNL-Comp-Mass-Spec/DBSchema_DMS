/****** Object:  View [dbo].[V_AuxInfo_Value] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_AuxInfo_Value]
AS
SELECT Category_Target.[Name] AS Target,
       Val.Target_ID,
       Category.[Name] AS Category,
       Subcategory.[Name] AS Subcategory,
       Item.[Name] AS Item,
       Val.[Value],
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
     INNER JOIN T_AuxInfo_Value Val
       ON Item.ID = Val.AuxInfo_ID
     INNER JOIN T_AuxInfo_Target Category_Target
       ON Category.Target_Type_ID = Category_Target.ID
WHERE Item.Active = 'Y'


GO
GRANT VIEW DEFINITION ON [dbo].[V_AuxInfo_Value] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_AuxInfo_Value] TO [PNL\D3M580] AS [dbo]
GO
