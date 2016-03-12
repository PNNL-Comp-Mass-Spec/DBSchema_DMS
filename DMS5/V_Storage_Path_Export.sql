/****** Object:  View [dbo].[V_Storage_Path_Export] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Storage_Path_Export]
As
SELECT SP_path_ID AS ID,
       SP_path AS [Path],
       SP_machine_name AS MachineName,
       SP_vol_name_client AS VolClient,
       SP_vol_name_server AS VolServer,
       SP_function AS [Function],
       SP_instrument_name AS Instrument,
	   SP_description AS Description,
       SP_Created as Created
FROM T_Storage_Path


GO
GRANT VIEW DEFINITION ON [dbo].[V_Storage_Path_Export] TO [PNL\D3M578] AS [dbo]
GO
