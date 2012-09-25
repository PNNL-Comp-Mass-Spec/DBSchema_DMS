/****** Object:  View [dbo].[V_Mage_FPkg_Data_Package_Datasets] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE view V_Mage_FPkg_Data_Package_Datasets as
SELECT  VMD.Dataset_ID ,
        VMD.Dataset ,
        VMD.Experiment ,
        VMD.Campaign ,
        VMD.State ,
        VMD.Instrument ,
        VMD.Created ,
        VMD.Type ,
        VMD.Comment ,
        TPD.Data_Package_ID ,
        TPD.[Package Comment] ,
        VMD.Folder ,
        VMD.Purged ,
        VMD.Storage_Path ,
        VMD.Archive_Path
FROM    V_Mage_FPkg_Dataset_List AS VMD
        INNER JOIN DMS_Data_Package.dbo.T_Data_Package_Datasets AS TPD ON VMD.Dataset_ID = TPD.Dataset_ID
        
GO
GRANT VIEW DEFINITION ON [dbo].[V_Mage_FPkg_Data_Package_Datasets] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Mage_FPkg_Data_Package_Datasets] TO [PNL\D3M580] AS [dbo]
GO
