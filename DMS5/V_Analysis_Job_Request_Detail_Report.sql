/****** Object:  View [dbo].[V_Analysis_Job_Request_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Analysis_Job_Request_Detail_Report]
AS
SELECT AJR.AJR_requestID AS Request,
       AJR.AJR_requestName AS Name,
       AJR.AJR_created AS Created,
       AJR.AJR_analysisToolName AS Tool,
       AJR.AJR_parmFileName AS [Parameter File],
       AJR.AJR_settingsFileName AS [Settings File],
       Org.OG_name AS Organism,
       AJR.AJR_proteinCollectionList AS [Protein Collection List],
       AJR.AJR_proteinOptionsList AS [Protein Options],
       AJR.AJR_organismDBName AS [Legacy Fasta],
       dbo.GetJobRequestDatasetNameList(AJR.AJR_requestID) As Datasets,
       AJR.Data_Package_ID AS [Data Package ID],
       AJR.AJR_comment AS [Comment],
       AJR.AJR_specialProcessing AS [Special Processing],
       U.U_Name AS [Requestor Name],
       U.U_PRN AS Requestor,
       ARS.StateName AS State,
       dbo.GetJobRequestInstrList(AJR.AJR_requestID) AS Instruments,
       dbo.GetJobRequestExistingJobList(AJR.AJR_requestID) AS [Pre-existing Jobs],
       IsNull(JobsQ.Jobs, 0) AS Jobs
FROM dbo.T_Analysis_Job_Request AS AJR
     INNER JOIN dbo.T_Users AS U
       ON AJR.AJR_requestor = U.ID
     INNER JOIN dbo.T_Analysis_Job_Request_State AS ARS
       ON AJR.AJR_state = ARS.ID
     INNER JOIN dbo.T_Organisms AS Org
       ON AJR.AJR_organism_ID = Org.Organism_ID
     LEFT OUTER JOIN (Select AJ_requestID, Count(*) As Jobs From dbo.T_Analysis_Job Group By AJ_requestID) JobsQ
       ON AJR.AJR_requestID = JobsQ.AJ_requestID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Analysis_Job_Request_Detail_Report] TO [DDL_Viewer] AS [dbo]
GO
