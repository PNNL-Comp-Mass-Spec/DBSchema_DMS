/****** Object:  View [dbo].[V_Dataset_Archive_Path] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Dataset_Archive_Path
AS
SELECT     dbo.T_Dataset_Archive.AS_Dataset_ID AS Dataset_ID, dbo.T_Archive_Path.AP_network_share_path AS Archive_Path
FROM         dbo.T_Archive_Path INNER JOIN
                      dbo.T_Dataset_Archive ON dbo.T_Archive_Path.AP_path_ID = dbo.T_Dataset_Archive.AS_storage_path_ID

GO
