/****** Object:  View [dbo].[V_MyEMSL_Supplemental_Metadata] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_MyEMSL_Supplemental_Metadata] 
AS 
SELECT DS.Dataset_ID AS [omics.dms.dataset_id],
       DS.Dataset_Num AS [omics.dms.dataset_name],
       E.Exp_ID AS [omics.dms.experiment_id],
       E.Experiment_Num AS [omics.dms.experiment_name],
       C.Campaign_ID AS [omics.dms.campaign_id],
       C.Campaign_Num AS [omics.dms.campaign_name],
       Org.Organism_ID AS [omics.dms.organism_id],
       Org.OG_name AS organism_name,
       Org.NCBI_Taxonomy_ID AS ncbi_taxonomy_id,
       DS.Acq_Time_Start AS [omics.dms.acquisition_time],
       DS.Acq_Length_Minutes AS [omics.dms.acquisition_length_min],
       DS.Scan_Count AS [omics.dms.number_of_scans],
       RR.RDS_Sec_Sep AS [omics.dms.separation_type],
       DTN.DST_name AS [omics.dms.dataset_type],
       RR.ID AS [omics.dms.requested_run_id]
FROM dbo.T_Campaign AS C
     LEFT OUTER JOIN dbo.T_Experiments AS E
       ON C.Campaign_ID = E.EX_campaign_ID
     LEFT OUTER JOIN dbo.T_Dataset AS DS
       ON E.Exp_ID = DS.Exp_ID
     LEFT OUTER JOIN dbo.T_DatasetTypeName AS DTN
       ON DS.DS_type_ID = DTN.DST_Type_ID
     LEFT OUTER JOIN dbo.T_Requested_Run AS RR
       ON DS.Dataset_ID = RR.DatasetID
     LEFT OUTER JOIN dbo.T_Organisms AS Org
       ON E.EX_organism_ID = Org.Organism_ID


GO
