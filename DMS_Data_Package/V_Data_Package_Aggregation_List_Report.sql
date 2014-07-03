/****** Object:  View [dbo].[V_Data_Package_Aggregation_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[V_Data_Package_Aggregation_List_Report]
AS
SELECT dbo.GetXMLRow(TD.Data_Package_ID, 'Job', TM.Job) AS [Sel.],
       TM.Job,
       TM.State,
       TM.Tool,
       TD.Dataset,
       TD.Dataset_ID,
       CASE
           WHEN TJ.Job IS NULL THEN 'No'
           ELSE 'Yes'
       END AS In_Package,
       TM.[Parm File],
       TM.Settings_File,
       TD.Data_Package_ID,
       TM.[Organism DB],
       TM.[Protein Collection List],
       TM.[Protein Options],
       DS.Rating,
	   DS.Instrument
FROM T_Data_Package_Datasets AS TD
     INNER JOIN S_V_Dataset_List_Report_2 AS DS
       ON TD.Dataset_ID = DS.ID
     LEFT OUTER JOIN S_V_Analysis_Job_List_Report_2 AS TM
       ON TD.Dataset = TM.Dataset
     LEFT OUTER JOIN T_Data_Package_Analysis_Jobs AS TJ
       ON TJ.Job = TM.Job AND
          TJ.Data_Package_ID = TD.Data_Package_ID




GO
