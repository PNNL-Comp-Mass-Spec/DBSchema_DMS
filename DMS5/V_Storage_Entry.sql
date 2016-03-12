/****** Object:  View [dbo].[V_Storage_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[V_Storage_Entry]
AS
SELECT SP_path, SP_vol_name_client, SP_vol_name_server, 
   SP_function, SP_instrument_name, 
   SP_description AS SP_description, SP_path_ID AS SP_ID
FROM dbo.t_storage_path

GO
GRANT VIEW DEFINITION ON [dbo].[V_Storage_Entry] TO [PNL\D3M578] AS [dbo]
GO
