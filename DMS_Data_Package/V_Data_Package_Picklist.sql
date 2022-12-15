/****** Object:  View [dbo].[V_Data_Package_Picklist] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Data_Package_Picklist]
AS
SELECT CONVERT(VARCHAR(12), ID) + CHAR(32) + Name AS label, 
       ID AS value 
FROM T_Data_Package


GO
