/****** Object:  View [dbo].[V_OSM_Package_Paths] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





CREATE VIEW [dbo].[V_OSM_Package_Paths]
AS
SELECT DP.ID, 
DPS.ID AS Path_ID, 
DPS.Path_Shared_Root,    
 CONVERT(VARCHAR(12), DATEPART(year, Created)) + '\' + CONVERT(VARCHAR(12), DP.ID) AS Path_Folder,
        DPS.Path_Shared_Root  + CONVERT(VARCHAR(12), DATEPART(year, Created)) + '\' + CONVERT(VARCHAR(12), DP.ID) AS Share_Path
FROM dbo.T_OSM_Package AS DP
     INNER JOIN dbo.T_OSM_Package_Storage AS DPS
       ON DP.Path_Root = DPS.ID







GO
GRANT VIEW DEFINITION ON [dbo].[V_OSM_Package_Paths] TO [DDL_Viewer] AS [dbo]
GO
