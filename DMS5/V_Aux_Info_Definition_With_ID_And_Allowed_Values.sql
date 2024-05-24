/****** Object:  View [dbo].[V_Aux_Info_Definition_With_ID_And_Allowed_Values] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Aux_Info_Definition_With_ID_And_Allowed_Values]
AS
SELECT Category_Target.Target_Type_Name AS target,
       Category.Target_Type_ID AS target_type_id,
       Category.Aux_Category AS category,
       Category.Aux_Category_ID AS cat_id,
       Subcategory.Aux_Subcategory AS subcategory,
       Subcategory.Aux_Subcategory_ID AS sub_id,
       Item.Aux_Description AS item,
       Item.Aux_Description_ID AS item_id,
       Category.[Sequence] AS cat_seq,
       Subcategory.[Sequence] AS sub_seq,
       Item.[Sequence] AS item_seq,
       Item.DataSize as data_size,
       Item.HelperAppend as helper_append,
       dbo.get_aux_info_allowed_values(Item.Aux_Description_ID) AS Allowed_Values
FROM T_Aux_Info_Category Category
     INNER JOIN T_Aux_Info_Subcategory Subcategory
       ON Category.Aux_Category_ID = Subcategory.Aux_Category_ID
     INNER JOIN T_Aux_Info_Description Item
       ON Subcategory.Aux_Subcategory_ID = Item.Aux_Subcategory_ID
     INNER JOIN T_Aux_Info_Target Category_Target
       ON Category.Target_Type_ID = Category_Target.Target_Type_ID
WHERE Item.Active = 'Y'

GO
GRANT VIEW DEFINITION ON [dbo].[V_Aux_Info_Definition_With_ID_And_Allowed_Values] TO [DDL_Viewer] AS [dbo]
GO
