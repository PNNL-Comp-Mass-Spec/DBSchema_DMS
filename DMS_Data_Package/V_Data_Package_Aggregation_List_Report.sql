/****** Object:  View [dbo].[V_Data_Package_Aggregation_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Data_Package_Aggregation_List_Report]
As
SELECT dbo.GetXMLRow(TD.Data_Package_ID, 'Job', TJ.Job) AS [Sel.],
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
     LEFT OUTER JOIN S_V_Dataset_List_Report_2 AS DS
       ON TD.Dataset_ID = DS.ID
     LEFT OUTER JOIN S_V_Analysis_Job_List_Report_2 AS TM
       ON TD.Dataset_ID = TM.Dataset_ID
     LEFT OUTER JOIN T_Data_Package_Analysis_Jobs AS TJ
       ON TJ.Job = TM.Job AND
          TJ.Dataset_ID = TD.Dataset_ID AND
          TJ.Data_Package_ID = TD.Data_Package_ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Data_Package_Aggregation_List_Report] TO [DDL_Viewer] AS [dbo]
GO
