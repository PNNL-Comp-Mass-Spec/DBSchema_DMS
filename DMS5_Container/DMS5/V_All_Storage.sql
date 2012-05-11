/****** Object:  View [dbo].[V_All_Storage] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO









/****** Object:  View dbo.V_All_Storage ******/

/****** Object:  View dbo.V_All_Storage    Script Date: 1/17/2001 2:15:33 PM ******/
CREATE VIEW dbo.V_All_Storage
AS
SELECT SP_path_ID, SP_path, SP_vol_name_client, 
   SP_vol_name_server, SP_function
FROM t_storage_path
WHERE (SP_function LIKE '%storage%')
GO
GRANT VIEW DEFINITION ON [dbo].[V_All_Storage] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_All_Storage] TO [PNL\D3M580] AS [dbo]
GO
