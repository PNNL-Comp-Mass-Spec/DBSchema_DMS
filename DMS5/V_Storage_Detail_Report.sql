/****** Object:  View [dbo].[V_Storage_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Storage_Detail_Report]
AS
SELECT SP_path_ID AS id, SP_path AS path,
   SP_vol_name_client AS vol_client,
   SP_vol_name_server AS vol_server,
   SP_function AS storage_path_function,
   SP_instrument_name AS instrument,
   SP_description AS description
FROM dbo.t_storage_path


GO
GRANT VIEW DEFINITION ON [dbo].[V_Storage_Detail_Report] TO [DDL_Viewer] AS [dbo]
GO
