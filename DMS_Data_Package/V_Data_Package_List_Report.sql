/****** Object:  View [dbo].[V_Data_Package_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Data_Package_List_Report]
AS
SELECT DP.id,
       DP.name,
       DP.description,
       ISNULL(OwnerInfo.u_name, DP.Owner) AS owner,
       DP.Path_Team AS team,
       DP.state,
       DP.package_type,
       ISNULL(RequesterInfo.u_name, DP.Requester) AS requester,
       DP.Total_Item_Count AS total,
       DP.Analysis_Job_Item_Count AS jobs,
       DP.Dataset_Item_Count AS datasets,
	   DP.EUS_Proposal_Item_Count AS proposals,
       DP.Experiment_Item_Count AS experiments,
       DP.Biomaterial_Item_Count AS biomaterial,
       DP.last_modified,
       DP.created,
       DP.data_doi,
       DP.manuscript_doi
FROM dbo.T_Data_Package DP
     LEFT OUTER JOIN S_V_Users OwnerInfo
       ON DP.Owner = OwnerInfo.U_PRN
     LEFT OUTER JOIN S_V_Users RequesterInfo
       ON DP.Requester = RequesterInfo.U_PRN


GO
GRANT VIEW DEFINITION ON [dbo].[V_Data_Package_List_Report] TO [DDL_Viewer] AS [dbo]
GO
GRANT SELECT ON [dbo].[V_Data_Package_List_Report] TO [DMS_SP_User] AS [dbo]
GO
