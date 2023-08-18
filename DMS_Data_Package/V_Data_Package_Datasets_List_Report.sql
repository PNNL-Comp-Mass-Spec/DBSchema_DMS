/****** Object:  View [dbo].[V_Data_Package_Datasets_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Data_Package_Datasets_List_Report]
AS
SELECT DPD.Data_Pkg_ID AS id,
       DPD.dataset,
       DPD.dataset_id,
       DPD.experiment,
       DPD.instrument,
       DPD.package_comment,
       DL.campaign,
       DL.state,
       DL.created,
       DL.rating,
       DL.dataset_folder_path,
       DL.acq_start,
       DL.acq_end,
       DL.acq_length,
       DL.scan_count,
       DL.lc_column,
       DL.separation_type,
       DL.request,
       DPD.item_added,
       DL.comment,
       DL.Dataset_Type AS type,
       DL.proposal,
	   PSM.Jobs AS psm_jobs,
	   PSM.max_total_psms,
	   PSM.max_unique_peptides,
	   PSM.max_unique_proteins,
	   PSM.max_unique_peptides_fdr_filter
FROM dbo.T_Data_Package_Datasets AS DPD
     INNER JOIN dbo.S_V_Dataset_List_Report_2 AS DL
       ON DPD.Dataset_ID = DL.ID
	 LEFT OUTER JOIN dbo.S_V_Analysis_Job_PSM_Summary_Export PSM
	   ON DPD.Dataset_ID = PSM.Dataset_ID

GO
GRANT VIEW DEFINITION ON [dbo].[V_Data_Package_Datasets_List_Report] TO [DDL_Viewer] AS [dbo]
GO
GRANT SELECT ON [dbo].[V_Data_Package_Datasets_List_Report] TO [DMS_SP_User] AS [dbo]
GO
