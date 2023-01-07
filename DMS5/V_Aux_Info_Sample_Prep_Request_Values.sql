/****** Object:  View [dbo].[V_Aux_Info_Sample_Prep_Request_Values] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Aux_Info_Sample_Prep_Request_Values]
AS
SELECT T_Sample_Prep_Request.Request_Name AS request,
       T_Sample_Prep_Request.ID AS id,
       T_Aux_Info_Category.Aux_Category AS category,
       T_Aux_Info_Subcategory.Aux_Subcategory AS subcategory,
       T_Aux_Info_Description.Aux_Description AS item,
       T_Aux_Info_Value.value
FROM T_Aux_Info_Category
     INNER JOIN T_Aux_Info_Subcategory
       ON T_Aux_Info_Category.Aux_Category_ID = T_Aux_Info_Subcategory.Aux_Category_ID
     INNER JOIN T_Aux_Info_Description
       ON T_Aux_Info_Subcategory.Aux_Subcategory_ID = T_Aux_Info_Description.Aux_Subcategory_ID
     INNER JOIN T_Aux_Info_Value
       ON T_Aux_Info_Description.Aux_Description_ID = T_Aux_Info_Value.Aux_Description_ID
     INNER JOIN T_Sample_Prep_Request
       ON T_Aux_Info_Value.Target_ID = T_Sample_Prep_Request.ID
WHERE T_Aux_Info_Category.Target_Type_ID = 503


GO
GRANT VIEW DEFINITION ON [dbo].[V_Aux_Info_Sample_Prep_Request_Values] TO [DDL_Viewer] AS [dbo]
GO
