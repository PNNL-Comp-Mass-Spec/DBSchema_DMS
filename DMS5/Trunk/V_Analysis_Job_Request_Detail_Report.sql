/****** Object:  View [dbo].[V_Analysis_Job_Request_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Analysis_Job_Request_Detail_Report]
AS
SELECT AR.AJR_requestID AS Request, 
    AR.AJR_requestName AS Name, AR.AJR_created AS Created, 
    AR.AJR_analysisToolName AS Tool, 
    AR.AJR_parmFileName AS [Parameter File], 
    AR.AJR_settingsFileName AS [Settings File], 
    Org.OG_name AS Organism, 
    AR.AJR_organismDBName AS [Organism DB], 
    AR.AJR_proteinCollectionList AS [Protein Collection List], 
    AR.AJR_proteinOptionsList AS [Protein Options], 
    AR.AJR_datasets AS Datasets, 
    AR.AJR_comment AS Comment, 
    U.U_Name AS [Requestor Name], U.U_PRN AS Requestor, 
    AR.AJR_workPackage AS [Work Package], 
    ARS.StateName AS State, 
    dbo.GetRunRequestInstrList(AR.AJR_requestID) 
    AS Instruments, 
    dbo.GetRunRequestExistingJobList(AR.AJR_requestID) 
    AS [Pre-existing Jobs], 
    case when COUNT(AJ.AJ_jobID) = 0 then null else COUNT(AJ.AJ_jobID) end AS Jobs
FROM T_Analysis_Job_Request AR INNER JOIN
    T_Users U ON AR.AJR_requestor = U.ID INNER JOIN
    T_Analysis_Job_Request_State ARS ON 
    AR.AJR_state = ARS.ID INNER JOIN
    T_Organisms Org ON 
    AR.AJR_organism_ID = Org.Organism_ID LEFT OUTER JOIN
    T_Analysis_Job AJ ON 
    AR.AJR_requestID = AJ.AJ_requestID
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
    U.U_Name, U.U_PRN, 
    AR.AJR_workPackage, 
    ARS.StateName

GO
