/****** Object:  View [dbo].[V_Storage_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Storage_List_Report]
AS
SELECT     dbo.t_storage_path.SP_path_ID AS ID, dbo.t_storage_path.SP_path AS Path, dbo.t_storage_path.SP_vol_name_client AS [Vol Client], 
                      dbo.t_storage_path.SP_vol_name_server AS [Vol Server], dbo.t_storage_path.SP_function AS [Function], 
                      dbo.t_storage_path.SP_instrument_name AS Instrument, dbo.t_storage_path.SP_description AS Description, COUNT(dbo.T_Dataset.Dataset_ID) 
                      AS Datasets
FROM         dbo.t_storage_path LEFT OUTER JOIN
                      dbo.T_Dataset ON dbo.t_storage_path.SP_path_ID = dbo.T_Dataset.DS_storage_path_ID
GROUP BY dbo.t_storage_path.SP_path_ID, dbo.t_storage_path.SP_path, dbo.t_storage_path.SP_vol_name_client, dbo.t_storage_path.SP_vol_name_server, 
                      dbo.t_storage_path.SP_function, dbo.t_storage_path.SP_instrument_name, dbo.t_storage_path.SP_description


GO
GRANT VIEW DEFINITION ON [dbo].[V_Storage_List_Report] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Storage_List_Report] TO [PNL\D3M580] AS [dbo]
GO
