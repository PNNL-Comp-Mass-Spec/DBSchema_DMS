/****** Object:  View [dbo].[V_Analysis_Job_Request_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE  VIEW dbo.V_Analysis_Job_Request_Detail_Report
AS
SELECT  AR.AJR_requestID AS Request, AR.AJR_requestName AS Name, 
        AR.AJR_created AS Created, AR.AJR_analysisToolName AS Tool, 
        AR.AJR_parmFileName AS [Parameter File], AR.AJR_settingsFileName AS [Settings File], 
        AR.AJR_organismName AS Organism, AR.AJR_organismDBName AS [Organism DB], 
        AR.AJR_proteinCollectionList AS [Protein Collection List], 
        AR.AJR_proteinOptionsList AS [Protein Options], AR.AJR_datasets AS Datasets, 
        AR.AJR_comment AS Comment, U.U_Name AS [Requestor Name], U.U_PRN AS Requestor, 
        AR.AJR_workPackage AS [Work Package], ARS.StateName AS State, dbo.GetRunRequestInstrList(AR.AJR_requestID) AS Instruments, 
        dbo.GetRunRequestExistingJobList(AR.AJR_requestID) AS [Pre-existing Jobs]
FROM    T_Analysis_Job_Request AR INNER JOIN
        T_Users U ON AR.AJR_requestor = U.ID INNER JOIN
        T_Analysis_Job_Request_State ARS ON AR.AJR_state = ARS.ID



GO
