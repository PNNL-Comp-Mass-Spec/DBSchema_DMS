/****** Object:  View [dbo].[V_Auxinfo_SamplePrepRequest_Values] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create View V_Auxinfo_SamplePrepRequest_Values as 
SELECT  T_Sample_Prep_Request.Request_Name AS Request ,
        T_AuxInfo_Value.Target_ID AS ID ,
        T_AuxInfo_Category.Name AS Category ,
        T_AuxInfo_Subcategory.Name AS Subcategory ,
        T_AuxInfo_Description.Name AS Item ,
        T_AuxInfo_Value.Value 
FROM    T_AuxInfo_Category
        INNER JOIN T_AuxInfo_Subcategory ON T_AuxInfo_Category.ID = T_AuxInfo_Subcategory.Parent_ID
        INNER JOIN T_AuxInfo_Description ON T_AuxInfo_Subcategory.ID = T_AuxInfo_Description.Parent_ID
        INNER JOIN T_AuxInfo_Value ON T_AuxInfo_Description.ID = T_AuxInfo_Value.AuxInfo_ID
        INNER JOIN T_Sample_Prep_Request ON T_AuxInfo_Value.Target_ID = T_Sample_Prep_Request.ID
WHERE   ( T_AuxInfo_Category.Target_Type_ID = 503 )
GO
