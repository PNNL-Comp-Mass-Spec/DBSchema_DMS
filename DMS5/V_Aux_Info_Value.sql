/****** Object:  View [dbo].[V_Aux_Info_Value] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Aux_Info_Value]
AS
SELECT Category_Target.Target_Type_Name AS target,
       Val.target_id,
       Category.Aux_Category AS category,
       Subcategory.Aux_Subcategory AS subcategory,
       Item.Aux_Description AS item,
       Val.value,
       Category.[Sequence] AS sc,
       Subcategory.[Sequence] AS ss,
       Item.[Sequence] AS si,
       Item.DataSize As data_size,
       Item.HelperAppend As helper_append
FROM T_Aux_Info_Category Category
     INNER JOIN T_Aux_Info_Subcategory Subcategory
       ON Category.Aux_Category_ID = Subcategory.Aux_Category_ID
     INNER JOIN T_Aux_Info_Description Item
       ON Subcategory.Aux_Subcategory_ID = Item.Aux_Subcategory_ID
     INNER JOIN T_Aux_Info_Value Val
       ON Item.Aux_Description_ID = Val.Aux_Description_ID
     INNER JOIN T_Aux_Info_Target Category_Target
       ON Category.Target_Type_ID = Category_Target.Target_Type_ID
WHERE Item.Active = 'Y'


GO
GRANT VIEW DEFINITION ON [dbo].[V_Aux_Info_Value] TO [DDL_Viewer] AS [dbo]
GO
