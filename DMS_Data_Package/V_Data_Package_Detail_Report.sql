/****** Object:  View [dbo].[V_Data_Package_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Data_Package_Detail_Report]
AS
SELECT DP.ID,
       DP.Name,
       DP.Package_Type AS [Package Type],
       DP.Description,
       DP.[Comment],
       ISNULL(U1.U_Name, DP.Owner) as Owner,
       ISNULL(U2.U_Name, DP.Requester) as Requester,
       DP.Path_Team AS Team,
       DP.Created,
       DP.Last_Modified AS [Last Modified],
       DP.State,
       DP.Package_File_Folder AS [Package File Folder],
       DPP.Share_Path AS [Share Path],
       DPP.Web_Path AS [Web Path],
       dbo.GetMyEMSLUrlDataPackageID(DP.ID) AS [MyEMSL URL],
       DP.Mass_Tag_Database AS [AMT Tag Database],
       DP.Biomaterial_Item_Count AS [Biomaterial Item Count],
       DP.Experiment_Item_Count AS [Experiment Item Count],
       DP.Dataset_Item_Count AS [Dataset Item Count],
       DP.Analysis_Job_Item_Count AS [Analysis Job Item Count],
       DP.Total_Item_Count AS [Total Item Count],
       DP.Wiki_Page_Link AS [PRISM Wiki]
FROM dbo.T_Data_Package AS DP
     INNER JOIN dbo.V_Data_Package_Paths AS DPP
       ON DP.ID = DPP.ID
     LEFT OUTER JOIN S_V_Users U1
       ON DP.Owner = U1.U_PRN
     LEFT OUTER JOIN S_V_Users U2
       ON DP.Requester = U2.U_PRN


GO
GRANT SELECT ON [dbo].[V_Data_Package_Detail_Report] TO [DMS_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Data_Package_Detail_Report] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Data_Package_Detail_Report] TO [PNL\D3M580] AS [dbo]
GO
