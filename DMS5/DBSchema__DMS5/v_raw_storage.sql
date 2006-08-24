/****** Object:  View [dbo].[v_raw_storage] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO









/****** Object:  View dbo.v_raw_storage ******/

/****** Object:  View dbo.v_raw_storage    Script Date: 1/17/2001 2:15:33 PM ******/
CREATE VIEW dbo.v_raw_storage
AS
SELECT SP_path_ID, SP_path, SP_vol_name_client, 
   SP_vol_name_server
FROM t_storage_path
WHERE (SP_function = N'raw-storage')
GO
