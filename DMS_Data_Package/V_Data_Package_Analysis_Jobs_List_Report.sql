/****** Object:  View [dbo].[V_Data_Package_Analysis_Jobs_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Data_Package_Analysis_Jobs_List_Report]
AS
SELECT DPJ.Data_Pkg_ID AS id,
       DPJ.job,
       AJL.dataset,
       AJL.dataset_id,
       AJL.tool,
       DPJ.package_comment,
       AJL.campaign,
       AJL.experiment,
       AJL.instrument,
       AJL.param_file,
       AJL.settings_file,
       AJL.organism,
       AJL.organism_db,
       AJL.protein_collection_list,
       AJL.protein_options,
	   AJL.state,
       AJL.finished,
       AJL.runtime_minutes,
       AJL.job_request,
       AJL.results_folder,
       AJL.results_folder_path,
       AJL.results_url,
       DPJ.item_added,
       AJL.comment
FROM dbo.T_Data_Package_Analysis_Jobs AS DPJ
     INNER JOIN dbo.S_V_Analysis_Job_List_Report_2 AS AJL
       ON DPJ.Job = AJL.Job

GO
GRANT VIEW DEFINITION ON [dbo].[V_Data_Package_Analysis_Jobs_List_Report] TO [DDL_Viewer] AS [dbo]
GO
GRANT SELECT ON [dbo].[V_Data_Package_Analysis_Jobs_List_Report] TO [DMS_SP_User] AS [dbo]
GO
