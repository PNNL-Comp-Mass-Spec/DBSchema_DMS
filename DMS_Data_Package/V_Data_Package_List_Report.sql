/****** Object:  View [dbo].[V_Data_Package_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Data_Package_List_Report]
AS
SELECT DP.ID,
       DP.Name,
       DP.Description,
       ISNULL(OwnerInfo.U_Name, DP.Owner) as Owner,
       DP.Path_Team as Team,
       DP.State,
       DP.Package_Type AS [Package Type],
       ISNULL(RequesterInfo.U_Name, DP.Requester) as Requester,
       DP.Total_Item_Count AS Total,
       DP.Analysis_Job_Item_Count AS Jobs,
       DP.Dataset_Item_Count AS Datasets,
	   DP.EUS_Proposal_Item_Count AS Proposals,
       DP.Experiment_Item_Count AS Experiments,
       DP.Biomaterial_Item_Count AS Biomaterial,
       DP.Last_Modified AS [Last Modified],
       DP.Created,
       DP.Data_DOI AS [Data DOI],
       DP.Manuscript_DOI AS [Manuscript DOI]
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
