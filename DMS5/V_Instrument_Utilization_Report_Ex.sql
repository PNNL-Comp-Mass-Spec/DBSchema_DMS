/****** Object:  View [dbo].[V_Instrument_Utilization_Report_Ex] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Instrument_Utilization_Report_Ex
AS
SELECT     dbo.T_Instrument_Name.IN_name AS Instrument, dbo.T_Dataset.DS_instrument_name_ID AS Instrument_ID, dbo.T_Dataset.Dataset_Num AS Dataset, 
                      dbo.T_Dataset.Dataset_ID, NULL AS Run_Start, dbo.T_Dataset.DS_created AS Run_Finish, dbo.T_Requested_Run.ID AS Request, 
                      dbo.T_Requested_Run.RDS_Oper_PRN AS Requester, 
                      dbo.t_storage_path.SP_vol_name_client + dbo.t_storage_path.SP_path + dbo.T_Dataset.DS_folder_name AS DatasetFolder
FROM         dbo.T_Dataset INNER JOIN
                      dbo.T_Instrument_Name ON dbo.T_Dataset.DS_instrument_name_ID = dbo.T_Instrument_Name.Instrument_ID INNER JOIN
                      dbo.T_DatasetTypeName ON dbo.T_Dataset.DS_type_ID = dbo.T_DatasetTypeName.DST_Type_ID INNER JOIN
                      dbo.t_storage_path ON dbo.T_Dataset.DS_storage_path_ID = dbo.t_storage_path.SP_path_ID LEFT OUTER JOIN
                      dbo.T_Requested_Run ON dbo.T_Dataset.Dataset_ID = dbo.T_Requested_Run.DatasetID
WHERE     (dbo.T_Dataset.DS_state_ID = 3)

GO
GRANT VIEW DEFINITION ON [dbo].[V_Instrument_Utilization_Report_Ex] TO [PNL\D3M578] AS [dbo]
GO
