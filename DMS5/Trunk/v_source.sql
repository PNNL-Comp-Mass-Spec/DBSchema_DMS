/****** Object:  View [dbo].[v_source] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO









/****** Object:  View dbo.v_source ******/

/****** Object:  View dbo.v_source    Script Date: 1/17/2001 2:15:33 PM ******/
CREATE VIEW dbo.v_source
AS
SELECT SP_path_ID, SP_path, SP_vol_name_server
FROM t_storage_path
WHERE (SP_function = N'inbox')
GO
GRANT VIEW DEFINITION ON [dbo].[v_source] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[v_source] TO [PNL\D3M580] AS [dbo]
GO
