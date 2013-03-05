/****** Object:  View [dbo].[V_OSM_Package_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_OSM_Package_Detail_Report
AS
SELECT        DP.ID, DP.Name, DP.Package_Type AS [Package Type], DP.Description, DP.Keywords, ISNULL(U1.U_Name, DP.Owner) AS Owner, DP.Created, 
                         DP.Last_Modified AS [Last Modified], DP.State, DP.Sample_Submission_Item_Count AS [Sample Submission Item Count], 
                         DP.Sample_Prep_Request_Item_Count AS [Sample Prep Request Item Count], DP.Material_Containers_Item_Count AS [Material Containers Item Count], 
                         DP.HPLC_Runs_Item_Count AS [HPLC Runs Item Count], DP.Experiment_Group_Item_Count AS [Experiment Group Item Count], 
                         DP.Experiment_Item_Count AS [Experiment Item Count], DP.Requested_Run_Item_Count, DP.Dataset_Item_Count, DP.Campaign_Item_Count, 
                         DP.Biomaterial_Item_Count AS [Biomaterial Item Count], DP.Total_Item_Count AS [Total Item Count], DP.Wiki_Page_Link AS [Wiki Page Link]
FROM            dbo.T_OSM_Package AS DP LEFT OUTER JOIN
                         dbo.S_V_Users AS U1 ON DP.Owner = U1.U_PRN

GO
