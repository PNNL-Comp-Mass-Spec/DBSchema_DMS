/****** Object:  View [dbo].[V_Data_Package_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Data_Package_Detail_Report]
AS
SELECT DP.id,
       DP.name,
       DP.package_type,
       DP.description,
       DP.comment,
       ISNULL(U1.u_name, DP.Owner) AS owner,
       ISNULL(U2.u_name, DP.Requester) AS requester,
       DP.Path_Team AS team,
       DP.created,
       DP.last_modified,
       DP.state,
       DP.package_file_folder,
       DPP.share_path,
       DPP.web_path,
       dbo.GetMyEMSLUrlDataPackageID(DP.ID) AS myemsl_url,
       DP.Mass_Tag_Database AS amt_tag_database,
       DP.biomaterial_item_count,
       DP.experiment_item_count,
       DP.eus_proposal_item_count,
       DP.dataset_item_count,
       DP.analysis_job_item_count,
       CampaignStats.Campaigns AS campaign_count,
       DP.Total_Item_Count AS total_item_count,
       DP.Wiki_Page_Link AS prism_wiki,
       DP.data_doi,
       DP.manuscript_doi,
	   DP.EUS_Person_ID AS eus_user_id,
	   DP.eus_proposal_id
FROM dbo.T_Data_Package AS DP
     INNER JOIN dbo.V_Data_Package_Paths AS DPP
       ON DP.ID = DPP.ID
     LEFT OUTER JOIN S_V_Users U1
       ON DP.Owner = U1.U_PRN
     LEFT OUTER JOIN S_V_Users U2
       ON DP.Requester = U2.U_PRN
     LEFT OUTER JOIN ( SELECT ID,
                              Count(*) AS Campaigns
                       FROM V_Data_Package_Campaigns_List_Report
                       GROUP BY ID ) AS CampaignStats
       ON DP.ID = CampaignStats.ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Data_Package_Detail_Report] TO [DDL_Viewer] AS [dbo]
GO
GRANT SELECT ON [dbo].[V_Data_Package_Detail_Report] TO [DMS_SP_User] AS [dbo]
GO
