/****** Object:  View [dbo].[V_Analysis_Job_Request_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW V_Analysis_Job_Request_Detail_Report
AS
SELECT AR.AJR_requestID AS Request,
       AR.AJR_requestName AS Name,
       AR.AJR_created AS Created,
       AR.AJR_analysisToolName AS Tool,
       AR.AJR_parmFileName AS [Parameter File],
       AR.AJR_settingsFileName AS [Settings File],
       Org.OG_name AS Organism,
       AR.AJR_proteinCollectionList AS [Protein Collection List],
       AR.AJR_proteinOptionsList AS [Protein Options],
       AR.AJR_organismDBName AS [Legacy Fasta],
       AR.AJR_datasets AS Datasets,
       AR.AJR_comment AS [Comment],
       AR.AJR_specialProcessing AS [Special Processing],
       U.U_Name AS [Requestor Name],
       U.U_PRN AS Requestor,
       AR.AJR_workPackage AS [Work Package],
       ARS.StateName AS State,
       dbo.GetRunRequestInstrList(AR.AJR_requestID) AS Instruments,
       dbo.GetRunRequestExistingJobList(AR.AJR_requestID) AS [Pre-existing Jobs],
       CASE
           WHEN COUNT(AJ.AJ_jobID) = 0 THEN NULL
           ELSE COUNT(AJ.AJ_jobID)
       END AS Jobs
FROM dbo.T_Analysis_Job_Request AS AR
     INNER JOIN dbo.T_Users AS U
       ON AR.AJR_requestor = U.ID
     INNER JOIN dbo.T_Analysis_Job_Request_State AS ARS
       ON AR.AJR_state = ARS.ID
     INNER JOIN dbo.T_Organisms AS Org
       ON AR.AJR_organism_ID = Org.Organism_ID
     LEFT OUTER JOIN dbo.T_Analysis_Job AS AJ
       ON AR.AJR_requestID = AJ.AJ_requestID
GROUP BY
    AR.AJR_requestID, 
    AR.AJR_requestName, AR.AJR_created, 
    AR.AJR_analysisToolName, 
    AR.AJR_parmFileName, 
    AR.AJR_settingsFileName, 
    Org.OG_name, 
    AR.AJR_organismDBName, 
    AR.AJR_proteinCollectionList, 
    AR.AJR_proteinOptionsList, 
    AR.AJR_datasets, 
    AR.AJR_comment, 
    AR.AJR_specialProcessing,
    U.U_Name, U.U_PRN, 
    AR.AJR_workPackage, 
    ARS.StateName

GO
GRANT VIEW DEFINITION ON [dbo].[V_Analysis_Job_Request_Detail_Report] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Analysis_Job_Request_Detail_Report] TO [PNL\D3M580] AS [dbo]
GO
