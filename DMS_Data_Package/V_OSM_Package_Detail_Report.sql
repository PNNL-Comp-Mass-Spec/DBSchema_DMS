/****** Object:  View [dbo].[V_OSM_Package_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_OSM_Package_Detail_Report]
AS
    SELECT  DP.ID ,
            DP.Name ,
            DP.Package_Type AS [Package Type] ,
            DP.Description ,
            DP.Keywords ,
            ISNULL(U1.U_Name, DP.Owner) AS Owner ,
            DP.Created ,
            DP.Last_Modified AS [Last Modified] ,
            DP.Sample_Prep_Requests AS [Sample Prep Requests] ,
            DP.State ,
            DP.Wiki_Page_Link AS [Wiki Page Link] ,
            DP.User_Folder_Path AS [User Folder],
            DPS.Share_Path AS [Managed Folder]
    FROM    dbo.T_OSM_Package AS DP
            LEFT OUTER JOIN dbo.S_V_Users AS U1 ON DP.Owner = U1.U_PRN
            LEFT OUTER JOIN V_OSM_Package_Paths DPS ON dp.ID = dps.ID



GO
GRANT VIEW DEFINITION ON [dbo].[V_OSM_Package_Detail_Report] TO [DDL_Viewer] AS [dbo]
GO
