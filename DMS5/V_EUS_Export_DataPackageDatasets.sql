/****** Object:  View [dbo].[V_EUS_Export_DataPackageDatasets] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_EUS_Export_DataPackageDatasets]
AS
SELECT D.Dataset_ID AS Dataset_ID,
       D.Dataset_Num AS Dataset,
       DP.ID AS Data_Package_ID,
       DP.Name AS Data_Package_Name,
       DP.State AS Data_Package_State,
       RR.RDS_EUS_Proposal_ID AS EUS_Proposal
FROM T_Dataset D
     INNER JOIN S_V_Data_Package_Datasets_Export DPD
       ON D.Dataset_ID = DPD.Dataset_ID
     INNER JOIN S_V_Data_Package_Export DP
       ON DP.ID = DPD.Data_Package_ID
     LEFT OUTER JOIN dbo.T_Requested_Run RR
       ON RR.DatasetID = D.Dataset_ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_EUS_Export_DataPackageDatasets] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_EUS_Export_DataPackageDatasets] TO [PNL\D3M580] AS [dbo]
GO
