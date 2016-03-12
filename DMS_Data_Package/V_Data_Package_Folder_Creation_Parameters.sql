/****** Object:  View [dbo].[V_Data_Package_Folder_Creation_Parameters] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Data_Package_Folder_Creation_Parameters]
AS
SELECT CONVERT(varchar(12), DP.ID) AS package,
       DPS.Path_Local_Root AS local,
       DPS.Path_Shared_Root AS share,
       DP.Path_Year AS year,
       DP.Path_Team AS team,
       DP.Package_File_Folder AS folder,
       DP.ID
FROM T_Data_Package DP
     INNER JOIN T_Data_Package_Storage DPS
       ON DP.Path_Root = DPS.ID



GO
GRANT VIEW DEFINITION ON [dbo].[V_Data_Package_Folder_Creation_Parameters] TO [PNL\D3M578] AS [dbo]
GO
