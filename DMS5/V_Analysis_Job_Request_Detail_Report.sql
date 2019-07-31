/****** Object:  View [dbo].[V_Analysis_Job_Request_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Analysis_Job_Request_Detail_Report]
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
       dbo.GetJobRequestDatasetNameList(AR.AJR_requestID) As Datasets,
       AR.AJR_comment AS [Comment],
       AR.AJR_specialProcessing AS [Special Processing],
       U.U_Name AS [Requestor Name],
       U.U_PRN AS Requestor,
       ARS.StateName AS State,
       dbo.GetJobRequestInstrList(AR.AJR_requestID) AS Instruments,
       dbo.GetJobRequestExistingJobList(AR.AJR_requestID) AS [Pre-existing Jobs],
       IsNull(JobsQ.Jobs, 0) AS Jobs
FROM dbo.T_Analysis_Job_Request AS AR
     INNER JOIN dbo.T_Users AS U
       ON AR.AJR_requestor = U.ID
     INNER JOIN dbo.T_Analysis_Job_Request_State AS ARS
       ON AR.AJR_state = ARS.ID
     INNER JOIN dbo.T_Organisms AS Org
       ON AR.AJR_organism_ID = Org.Organism_ID
     LEFT OUTER JOIN (Select AJ_requestID, Count(*) As Jobs From dbo.T_Analysis_Job Group By AJ_requestID) JobsQ
       ON AR.AJR_requestID = JobsQ.AJ_requestID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Analysis_Job_Request_Detail_Report] TO [DDL_Viewer] AS [dbo]
GO
