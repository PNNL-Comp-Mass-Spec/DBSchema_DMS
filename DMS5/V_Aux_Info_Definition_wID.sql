/****** Object:  View [dbo].[V_Aux_Info_Definition_wID] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Aux_Info_Definition_wID]
AS
SELECT Category_Target.[Name] AS Target,
       Category.Target_Type_ID AS TargT_ID,
       Category.[Name] AS Category,
       Category.ID AS Cat_ID,
       Subcategory.[Name] AS Subcategory,
       Subcategory.ID AS Sub_ID,
       Item.[Name] AS Item,
       Item.ID AS Item_ID,
       Category.[Sequence] AS Cat_Seq,
       Subcategory.[Sequence] AS Sub_Seq,
       Item.[Sequence] AS Item_Seq,
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
GRANT VIEW DEFINITION ON [dbo].[V_Aux_Info_Definition_wID] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Aux_Info_Definition_wID] TO [PNL\D3M580] AS [dbo]
GO
