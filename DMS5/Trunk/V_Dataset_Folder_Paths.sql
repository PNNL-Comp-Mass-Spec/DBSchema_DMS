/****** Object:  View [dbo].[V_Dataset_Folder_Paths] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW dbo.V_Dataset_Folder_Paths
AS
SELECT dbo.T_Dataset.Dataset_Num AS Dataset, 
    dbo.T_Dataset.Dataset_ID, 
    ISNULL(dbo.t_storage_path.SP_vol_name_client + dbo.t_storage_path.SP_path
     + dbo.T_Dataset.Dataset_Num, '') AS Dataset_Folder_Path, 
    ISNULL(dbo.V_Dataset_Archive_Path.Archive_Path + '\' + dbo.T_Dataset.Dataset_Num,
     '') AS Archive_Folder_Path
FROM dbo.T_Dataset INNER JOIN
    dbo.t_storage_path ON 
    dbo.T_Dataset.DS_storage_path_ID = dbo.t_storage_path.SP_path_ID
     LEFT OUTER JOIN
    dbo.V_Dataset_Archive_Path ON 
    dbo.T_Dataset.Dataset_ID = dbo.V_Dataset_Archive_Path.Dataset_ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Dataset_Folder_Paths] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Dataset_Folder_Paths] TO [PNL\D3M580] AS [dbo]
GO
