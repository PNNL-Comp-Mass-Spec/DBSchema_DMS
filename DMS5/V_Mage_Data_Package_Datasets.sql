/****** Object:  View [dbo].[V_Mage_Data_Package_Datasets] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Mage_Data_Package_Datasets]
AS
SELECT VMD.Dataset_ID,
       VMD.Dataset,
       VMD.Experiment,
       VMD.Campaign,
       VMD.State,
       VMD.Instrument,
       VMD.Created,
       VMD.Dataset_Type,
       VMD.Folder,
       VMD.Comment,
       TPD.Data_Pkg_ID,
       TPD.Package_Comment,
       VMD.Storage_Server_Folder,
       VMD.Dataset_Type AS Type,            -- Included for compatibility with older versions of Mage
       TPD.Data_Pkg_ID AS Data_Package_ID   -- Included for compatibility with older versions of Mage
FROM V_Mage_Dataset_List AS VMD
     INNER JOIN DMS_Data_Package.dbo.T_Data_Package_Datasets AS TPD
       ON VMD.Dataset_ID = TPD.Dataset_ID

GO
GRANT VIEW DEFINITION ON [dbo].[V_Mage_Data_Package_Datasets] TO [DDL_Viewer] AS [dbo]
GO
