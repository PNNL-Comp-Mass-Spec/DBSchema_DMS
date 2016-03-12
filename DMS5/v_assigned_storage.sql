/****** Object:  View [dbo].[V_assigned_storage] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW dbo.v_assigned_storage
AS
SELECT T_Instrument_Name.IN_name, 
   T_Instrument_Name.IN_capture_method, 
   VS.SP_vol_name_server AS sourceVol, 
   VS.SP_path AS sourcePath, 
   VR.SP_vol_name_client AS clientStorageVol, 
   VR.SP_vol_name_server AS serverStorageVol, 
   VR.SP_path AS storagePath, 
   T_Instrument_Name.IN_source_path_ID, 
   T_Instrument_Name.IN_storage_path_ID, 
   T_Instrument_Name.Instrument_ID,
   VR.SP_machine_name
FROM T_Instrument_Name INNER JOIN
   (
			SELECT     SP_path_ID, SP_path, SP_vol_name_server
			FROM         dbo.t_storage_path
			WHERE     (SP_function = N'inbox')
		) VS ON T_Instrument_Name.IN_source_path_ID = VS.SP_path_ID INNER JOIN
		(
			SELECT SP_path_ID, SP_path, SP_vol_name_client, SP_vol_name_server, SP_machine_name
			FROM         dbo.t_storage_path
			WHERE     (SP_function = N'raw-storage')
		) VR ON T_Instrument_Name.IN_storage_path_ID = VR.SP_path_ID
   

   


GO
GRANT VIEW DEFINITION ON [dbo].[V_assigned_storage] TO [PNL\D3M578] AS [dbo]
GO
