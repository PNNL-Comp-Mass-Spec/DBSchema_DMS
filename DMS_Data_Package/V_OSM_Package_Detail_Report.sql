/****** Object:  View [dbo].[V_OSM_Package_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_OSM_Package_Detail_Report]
AS
SELECT DP.id,
        DP.name,
        DP.package_type,
        DP.description,
        DP.keywords,
        ISNULL(U1.u_name, DP.Owner) AS owner,
        DP.created,
        DP.last_modified,
        DP.sample_prep_requests,
        DP.state,
        DP.wiki_page_link,
        DP.User_Folder_Path AS user_folder,
        DPS.Share_Path AS managed_folder
FROM dbo.T_OSM_Package AS DP
        LEFT OUTER JOIN dbo.S_V_Users AS U1 ON DP.Owner = U1.U_PRN
        LEFT OUTER JOIN V_OSM_Package_Paths DPS ON dp.ID = dps.ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_OSM_Package_Detail_Report] TO [DDL_Viewer] AS [dbo]
GO
