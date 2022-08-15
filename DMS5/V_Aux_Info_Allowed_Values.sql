/****** Object:  View [dbo].[V_Aux_Info_Allowed_Values] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Aux_Info_Allowed_Values]
AS
SELECT Category_Target.[Name] AS Target,
       Category.[Name] AS Category,
       Subcategory.[Name] AS Subcategory,
       Item.[Name] AS Item,
       AllowedVals.[Value] AS AllowedValue
FROM T_AuxInfo_Category Category
     INNER JOIN T_AuxInfo_Subcategory Subcategory
       ON Category.ID = Subcategory.Aux_Category_ID
     INNER JOIN T_AuxInfo_Description Item
       ON Subcategory.ID = Item.Aux_Subcategory_ID
     INNER JOIN T_AuxInfo_Target Category_Target
       ON Category.Target_Type_ID = Category_Target.ID
     INNER JOIN T_AuxInfo_Allowed_Values AllowedVals
       ON Item.ID = AllowedVals.Aux_Description_ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Aux_Info_Allowed_Values] TO [DDL_Viewer] AS [dbo]
GO
