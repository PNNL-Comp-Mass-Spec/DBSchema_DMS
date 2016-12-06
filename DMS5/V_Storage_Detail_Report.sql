/****** Object:  View [dbo].[V_Storage_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE VIEW [dbo].[V_Storage_Detail_Report]
AS
SELECT SP_path_ID AS ID, SP_path AS Path, 
   SP_vol_name_client AS [Vol Client], 
   SP_vol_name_server AS [Vol Server], 
   SP_function AS [Function], SP_instrument_name AS Instrument, 
   SP_description AS Description
FROM dbo.t_storage_path


GO
GRANT VIEW DEFINITION ON [dbo].[V_Storage_Detail_Report] TO [DDL_Viewer] AS [dbo]
GO
