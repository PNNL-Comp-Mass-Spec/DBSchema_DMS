/****** Object:  View [dbo].[V_Analysis_Job_Request_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Analysis_Job_Request_Detail_Report]
AS
SELECT AJR.AJR_requestID AS request,
       AJR.AJR_requestName AS name,
       AJR.AJR_created AS created,
       AJR.AJR_analysisToolName AS tool,
       AJR.AJR_parmFileName AS parameter_file,
       AJR.AJR_settingsFileName AS settings_file,
       Org.OG_name AS organism,
       AJR.AJR_proteinCollectionList AS protein_collection_list,
       AJR.AJR_proteinOptionsList AS protein_options,
       AJR.AJR_organismDBName AS legacy_fasta,
       dbo.get_job_request_dataset_name_list(AJR.AJR_requestID) As datasets,
       AJR.Data_Package_ID AS data_package_id,
       AJR.AJR_comment AS comment,
       AJR.AJR_specialProcessing AS special_processing,
       U.U_Name AS requester_name,
       U.U_PRN AS requester,
       ARS.StateName AS state,
       dbo.get_job_request_instr_list(AJR.AJR_requestID) AS instruments,
       dbo.get_job_request_existing_job_list(AJR.AJR_requestID) AS pre_existing_jobs,
       IsNull(JobsQ.Jobs, 0) AS jobs
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
