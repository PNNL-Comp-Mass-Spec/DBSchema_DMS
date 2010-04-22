/****** Object:  View [dbo].[V_Old_Storage] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO







CREATE VIEW dbo.V_Old_Storage
AS
SELECT SP_path_ID, SP_path, SP_vol_name_client, 
   SP_vol_name_server, SP_function, SP_instrument_name
FROM t_storage_path
WHERE (SP_function = N'old-storage')
GO
GRANT VIEW DEFINITION ON [dbo].[V_Old_Storage] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Old_Storage] TO [PNL\D3M580] AS [dbo]
GO
