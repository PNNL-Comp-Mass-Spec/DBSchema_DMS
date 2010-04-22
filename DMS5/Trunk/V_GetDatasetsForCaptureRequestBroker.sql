/****** Object:  View [dbo].[V_GetDatasetsForCaptureRequestBroker] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_GetDatasetsForCaptureRequestBroker
AS
SELECT     dbo.T_Dataset.Dataset_ID, dbo.T_Dataset.DS_state_ID AS State, dbo.t_storage_path.SP_machine_name AS Storage_Server_Name, 
                      dbo.T_Dataset.DS_PrepServerName AS Prep_Server_Name, dbo.T_Instrument_Name.IN_name AS Instrument_Name, 
                      dbo.T_Dataset.DS_Last_Affected AS Last_Affected, dbo.t_storage_path.SP_path_ID AS Storage_Path_ID
FROM         dbo.T_Dataset INNER JOIN
                      dbo.T_Instrument_Name ON dbo.T_Dataset.DS_instrument_name_ID = dbo.T_Instrument_Name.Instrument_ID INNER JOIN
                      dbo.t_storage_path ON dbo.T_Instrument_Name.IN_storage_path_ID = dbo.t_storage_path.SP_path_ID
WHERE     (dbo.t_storage_path.SP_function = N'raw-storage') AND (dbo.T_Dataset.DS_state_ID IN (1, 2, 6, 7))

GO
GRANT VIEW DEFINITION ON [dbo].[V_GetDatasetsForCaptureRequestBroker] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_GetDatasetsForCaptureRequestBroker] TO [PNL\D3M580] AS [dbo]
GO
