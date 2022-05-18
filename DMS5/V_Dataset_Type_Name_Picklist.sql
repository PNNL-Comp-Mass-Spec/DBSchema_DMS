/****** Object:  View [dbo].[V_Dataset_Type_Name_Picklist] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW V_Dataset_Type_Name_Picklist
AS
SELECT DST_Type_ID As ID, DST_name As Name, DST_Description As Description, DST_Name + ' ... [' + DST_Description + ']' As Name_with_Description
FROM T_DatasetTypeName
WHERE DST_Active > 0


GO
GRANT VIEW DEFINITION ON [dbo].[V_Dataset_Type_Name_Picklist] TO [DDL_Viewer] AS [dbo]
GO
