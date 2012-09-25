/****** Object:  View [dbo].[V_Data_Package_Analysis_Jobs_Export] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[V_Data_Package_Analysis_Jobs_Export]
AS
SELECT PJ.Data_Package_ID,
       PJ.Job,
       PJ.Dataset,
       PJ.Tool,
       PJ.[Package Comment],
       PJ.[Item Added],
       MJ.Folder
FROM dbo.T_Data_Package_Analysis_Jobs PJ
     LEFT OUTER JOIN S_DMS_V_Mage_Analysis_Jobs MJ
       ON PJ.Job = MJ.Job


GO
