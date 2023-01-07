/****** Object:  View [dbo].[V_Helper_Dataset_Type] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Helper_Dataset_Type]
AS
SELECT DST_Name AS dataset_type,
       DST_Description AS description,
       T_YesNo.Description AS active
FROM dbo.T_DatasetTypeName D
     INNER JOIN dbo.T_YesNo
       ON D.DST_Active = T_YesNo.Flag


GO
GRANT VIEW DEFINITION ON [dbo].[V_Helper_Dataset_Type] TO [DDL_Viewer] AS [dbo]
GO
