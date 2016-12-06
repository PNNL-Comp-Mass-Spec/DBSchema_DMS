/****** Object:  View [dbo].[V_Data_Package_Export] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE VIEW [dbo].[V_Data_Package_Export]
AS
SELECT DP.ID,
       DP.Name,
       DP.Description,
       DP.Owner,
       DP.Path_Team AS Team,
       DP.State,
       DP.Package_Type AS [Package Type],
       DP.Requester,
       DP.Total_Item_Count AS Total,
       DP.Analysis_Job_Item_Count AS Jobs,
       DP.Dataset_Item_Count AS Datasets,
       DP.Experiment_Item_Count AS Experiments,
       DP.Biomaterial_Item_Count AS Biomaterial,
       DP.Last_Modified AS [Last Modified],
       DP.Created,
       DP.Package_File_Folder,
       DPP.Storage_Path_Relative,
       DPP.Share_Path,
       DPP.Archive_Path,
       DPP.Local_Path,
	   DP.EUS_Person_ID,
	   DP.EUS_Proposal_ID,
       IsNull(UploadQ.MyEmsl_Uploads, 0) As MyEMSL_Uploads
FROM T_Data_Package DP
     INNER JOIN V_Data_Package_Paths DPP
       ON DP.ID = DPP.ID
     LEFT OUTER JOIN ( SELECT Data_Package_ID,
                              COUNT(*) AS MyEMSL_Uploads
                       FROM T_MyEMSL_Uploads
                       WHERE (ErrorCode = 0) AND
                             (StatusNum > 1) AND
                             (FileCountNew > 0 OR
                              FileCountUpdated > 0)
                       GROUP BY Data_Package_ID 
					 ) UploadQ
       ON DP.ID = UploadQ.Data_Package_ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Data_Package_Export] TO [DDL_Viewer] AS [dbo]
GO
