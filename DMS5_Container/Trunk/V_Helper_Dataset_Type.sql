/****** Object:  View [dbo].[V_Helper_Dataset_Type] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Helper_Dataset_Type
AS
SELECT     DST_Name AS Dataset_Type, DST_Description AS Description, CASE WHEN DST_Active = 0 THEN 'No' ELSE 'Yes' END AS Active
FROM         dbo.T_DatasetTypeName

GO
