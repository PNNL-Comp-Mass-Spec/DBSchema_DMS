/****** Object:  View [dbo].[V_Dataset_Type_Name_Export] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW V_Dataset_Type_Name_Export
AS
SELECT DST_Type_ID As Dataset_Type_ID, DST_name As Dataset_Type, DST_Description As Description, DST_Active As Active
FROM T_DatasetTypeName


GO
