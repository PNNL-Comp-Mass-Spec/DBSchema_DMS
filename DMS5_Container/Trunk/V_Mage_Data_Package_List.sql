/****** Object:  View [dbo].[V_Mage_Data_Package_List] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW V_Mage_Data_Package_List AS
SELECT  ID ,
        Name AS Package ,
        Description ,
        Owner ,
        Team ,
        State ,
        [Package Type] ,
        [Last Modified] ,
        Created ,
        Share_Path AS Folder ,
        REPLACE(Share_Path, 'protoapps', 'a1.emsl.pnl.gov\prismarch') AS Archive_Path
FROM    S_V_Data_Package_Export    
GO
