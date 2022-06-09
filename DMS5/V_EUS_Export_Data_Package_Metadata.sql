/****** Object:  View [dbo].[V_EUS_Export_Data_Package_Metadata] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_EUS_Export_Data_Package_Metadata]
AS
SELECT ID,
       Name,
       Description,
       Owner AS Owner_PRN,
       Team,
       State,
       Package_Type As [Package Type],
       Total AS Total_Items,
       Jobs,
       Datasets,
       Experiments,
       Biomaterial,
       Last_Modified As [Last Modified],
       Created,
       Package_File_Folder,
       Storage_Path_Relative,
       Share_Path,
       Archive_Path
FROM DMS_Data_Package.dbo.V_Data_Package_Export

GO
GRANT VIEW DEFINITION ON [dbo].[V_EUS_Export_Data_Package_Metadata] TO [DDL_Viewer] AS [dbo]
GO
