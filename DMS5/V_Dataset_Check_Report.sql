/****** Object:  View [dbo].[V_Dataset_Check_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW V_Dataset_Check_Report
AS
SELECT     dbo.T_Dataset.Dataset_ID, dbo.T_Dataset.Dataset_Num AS Dataset, dbo.T_Dataset.DS_created AS Created, 
                      dbo.T_DatasetStateName.DSS_name AS State, dbo.T_Event_Log.Entered AS [State Date], dbo.t_storage_path.SP_machine_name AS Storage, 
                      dbo.T_Instrument_Name.IN_name AS Instrument, dbo.T_Dataset.DS_PrepServerName AS [Prep Server]
FROM         dbo.T_Dataset INNER JOIN
                      dbo.T_Event_Log ON dbo.T_Dataset.Dataset_ID = dbo.T_Event_Log.Target_ID AND 
                      dbo.T_Dataset.DS_state_ID = dbo.T_Event_Log.Target_State INNER JOIN
                      dbo.T_DatasetStateName ON dbo.T_Dataset.DS_state_ID = dbo.T_DatasetStateName.Dataset_state_ID INNER JOIN
                      dbo.t_storage_path ON dbo.T_Dataset.DS_storage_path_ID = dbo.t_storage_path.SP_path_ID INNER JOIN
                      dbo.T_Instrument_Name ON dbo.T_Dataset.DS_instrument_name_ID = dbo.T_Instrument_Name.Instrument_ID
WHERE     (dbo.T_Event_Log.Target_Type = 4) AND (dbo.T_Dataset.DS_state_ID <> 3) AND (dbo.T_Dataset.DS_state_ID <> 4)

GO
GRANT VIEW DEFINITION ON [dbo].[V_Dataset_Check_Report] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Dataset_Check_Report] TO [PNL\D3M580] AS [dbo]
GO
