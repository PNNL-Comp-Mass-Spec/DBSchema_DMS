/****** Object:  View [dbo].[V_Mage_Dataset_Factor_Summary] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW V_Mage_Dataset_Factor_Summary as
SELECT        T_Dataset.Dataset_ID AS ID, T_Dataset.Dataset_Num AS Dataset, T_Requested_Run.ID AS Request, COUNT(T_Factor.FactorID) AS Factors
FROM            T_Dataset INNER JOIN
                         T_Requested_Run ON T_Dataset.Dataset_ID = T_Requested_Run.DatasetID INNER JOIN
                         T_Factor ON T_Requested_Run.ID = T_Factor.TargetID
WHERE        (T_Factor.Type = 'Run_Request')
GROUP BY T_Dataset.Dataset_ID, T_Dataset.Dataset_Num, T_Requested_Run.ID, T_Requested_Run.RDS_Name

GO
GRANT VIEW DEFINITION ON [dbo].[V_Mage_Dataset_Factor_Summary] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Mage_Dataset_Factor_Summary] TO [PNL\D3M580] AS [dbo]
GO
