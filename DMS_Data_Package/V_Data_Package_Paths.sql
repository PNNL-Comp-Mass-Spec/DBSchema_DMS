/****** Object:  View [dbo].[V_Data_Package_Paths] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Data_Package_Paths]
AS
SELECT DP.ID,      
       DP.Package_File_Folder,
       DP.Path_Team + '\' + DP.Path_Year + '\' + DP.Package_File_Folder AS Storage_Path_Relative,
       DPS.Path_Shared_Root + DP.Path_Team + '\' + DP.Path_Year + '\' + DP.Package_File_Folder AS Share_Path,
       DPS.Path_Web_Root + DP.Path_Team + '/' + DP.Path_Year + '/' + DP.Package_File_Folder AS Web_Path,
       DPS.Path_Archive_Root + DP.Path_Team + '/' + DP.Path_Year + '/' + DP.Package_File_Folder AS Archive_Path,
       dbo.combine_paths(DPS.Path_Local_Root, DP.Path_Team) + '\' + DP.Path_Year + '\' + DP.Package_File_Folder AS Local_Path
FROM dbo.T_Data_Package AS DP
     INNER JOIN dbo.T_Data_Package_Storage AS DPS
       ON DP.Path_Root = DPS.ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Data_Package_Paths] TO [DDL_Viewer] AS [dbo]
GO
GRANT SELECT ON [dbo].[V_Data_Package_Paths] TO [DMS_SP_User] AS [dbo]
GO
