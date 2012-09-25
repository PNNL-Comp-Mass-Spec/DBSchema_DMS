/****** Object:  View [dbo].[V_Annotation_Type_Picker] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Annotation_Type_Picker] AS 
SELECT dbo.T_Annotation_Types.Annotation_Type_ID AS ID,
       dbo.T_Naming_Authorities.Name + ' - ' + dbo.T_Annotation_Types.TypeName AS Display_Name,
       COALESCE(dbo.T_Naming_Authorities.Description + ' <' + dbo.T_Naming_Authorities.Web_Address 
                + '>', '---') AS Details,
       dbo.T_Annotation_Types.Authority_ID
FROM dbo.T_Naming_Authorities
     INNER JOIN dbo.T_Annotation_Types
       ON dbo.T_Naming_Authorities.Authority_ID = dbo.T_Annotation_Types.Authority_ID

GO
