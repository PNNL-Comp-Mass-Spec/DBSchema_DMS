/****** Object:  View [dbo].[V_Data_Package_Datasets_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Data_Package_Datasets_List_Report]
AS
SELECT DPD.Data_Package_ID AS ID,
       DPD.Dataset,
       DPD.Dataset_ID,
       DPD.Experiment,
       DPD.Instrument,
       DPD.Package_Comment,
       DL.Campaign,
       DL.[State],
       DL.Created,
       DL.Rating,
       DL.[Dataset Folder Path],
       DL.[Acq Start],
       DL.[Acq End],
       DL.[Acq Length],
       DL.[Scan Count],
       DL.[LC Column],
       DL.[Separation Type],
       DL.Request,
       DPD.Item_Added,
       DL.[Comment],
       DL.[Dataset Type] AS [Type],
       DL.[Proposal],
	   PSM.Jobs AS [PSM Jobs],
	   PSM.Max_Total_PSMs AS [Max Total PSMs],
	   PSM.Max_Unique_Peptides AS [Max Unique Peptides],
	   PSM.Max_Unique_Proteins AS [Max Unique Proteins],
	   PSM.Max_Unique_Peptides_FDR_Filter AS [Max Unique Peptides FDR Filter]
FROM dbo.T_Data_Package_Datasets AS DPD
     INNER JOIN dbo.S_V_Dataset_List_Report_2 AS DL
       ON DPD.Dataset_ID = DL.ID
	 LEFT OUTER JOIN dbo.S_V_Analysis_Job_PSM_Summary_Export PSM
	   ON DPD.Dataset_ID = PSM.Dataset_ID



GO
GRANT VIEW DEFINITION ON [dbo].[V_Data_Package_Datasets_List_Report] TO [DDL_Viewer] AS [dbo]
GO
GRANT SELECT ON [dbo].[V_Data_Package_Datasets_List_Report] TO [DMS_SP_User] AS [dbo]
GO
