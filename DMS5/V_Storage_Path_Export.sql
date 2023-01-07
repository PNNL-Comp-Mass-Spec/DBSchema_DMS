/****** Object:  View [dbo].[V_Storage_Path_Export] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Storage_Path_Export]
As
SELECT SP_path_ID AS id,
       SP_path as storage_path,
       SP_machine_name AS machine_name,
       SP_vol_name_client AS vol_client,
       SP_vol_name_server AS vol_server,
       SP_function AS storage_path_function,
       SP_instrument_name AS instrument,
	   SP_description AS description,
       SP_Created as created,
       -- The following are old column names, included for compatibility with older versions of the Analysis Manager
       SP_path AS [Path],
       SP_machine_name AS MachineName,
       SP_vol_name_client AS VolClient,
       SP_vol_name_server AS VolServer,
       SP_function AS [Function]
FROM T_Storage_Path


GO
GRANT VIEW DEFINITION ON [dbo].[V_Storage_Path_Export] TO [DDL_Viewer] AS [dbo]
GO
