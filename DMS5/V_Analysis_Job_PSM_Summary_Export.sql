/****** Object:  View [dbo].[V_Analysis_Job_PSM_Summary_Export] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW V_Analysis_Job_PSM_Summary_Export
AS
SELECT AJ.AJ_datasetID AS Dataset_ID,
       Count(*) AS Jobs,
       IsNull(Max(PSM.Total_PSMs_FDR_Filter),      Max(PSM.Total_PSMs))      AS Max_Total_PSMs,
       IsNull(Max(PSM.Unique_Peptides_FDR_Filter), Max(PSM.Unique_Peptides)) AS Max_Unique_Peptides,
       IsNull(Max(PSM.Unique_Proteins_FDR_Filter), Max(PSM.Unique_Proteins)) AS Max_Unique_Proteins,
       Max(PSM.Total_PSMs)                 AS Max_Total_PSMs_MSGF,
       Max(PSM.Unique_Peptides)            AS Max_Unique_Peptides_MSGF,
       Max(PSM.Unique_Proteins)            AS Max_Unique_Proteins_MSGF,
       Max(PSM.Total_PSMs_FDR_Filter)      AS Max_Total_PSMs_FDR_Filter,
       Max(PSM.Unique_Peptides_FDR_Filter) AS Max_Unique_Peptides_FDR_Filter,
       Max(PSM.Unique_Proteins_FDR_Filter) AS Max_Unique_Proteins_FDR_Filter	   
FROM dbo.T_Analysis_Job AS AJ
     INNER JOIN dbo.T_Analysis_Job_PSM_Stats PSM
       ON AJ.AJ_JobID = PSM.Job
WHERE AJ.AJ_analysisToolID IN ( SELECT AJT_toolID
                                FROM T_Analysis_Tool
                                WHERE AJT_resultType LIKE '%peptide_hit' OR
                                      AJT_resultType = 'Gly_ID' )
GROUP BY AJ.AJ_datasetID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Analysis_Job_PSM_Summary_Export] TO [DDL_Viewer] AS [dbo]
GO
