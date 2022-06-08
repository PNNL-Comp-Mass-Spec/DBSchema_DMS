/****** Object:  View [dbo].[V_Mage_Data_Package_List] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE view [dbo].[V_Mage_Data_Package_List] as
SELECT  ID,
        Name AS Package,
        Description,
        Owner,
        Team,
        State,
        Package_Type,
        Last_Modified,
        Created,
        Share_Path AS Folder,
        '' AS Archive_Path
FROM    dbo.S_V_Data_Package_Export

GO
GRANT VIEW DEFINITION ON [dbo].[V_Mage_Data_Package_List] TO [DDL_Viewer] AS [dbo]
GO
