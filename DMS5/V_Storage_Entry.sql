/****** Object:  View [dbo].[V_Storage_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Storage_Entry]
AS
SELECT SP_path AS storage_path,
       SP_vol_name_client AS vol_name_client,
       SP_vol_name_server AS vol_name_server,
       SP_function AS storage_path_function,
       SP_instrument_name AS instrument,
       SP_description AS description,
       SP_path_ID AS storage_path_id
FROM dbo.t_storage_path


GO
GRANT VIEW DEFINITION ON [dbo].[V_Storage_Entry] TO [DDL_Viewer] AS [dbo]
GO
