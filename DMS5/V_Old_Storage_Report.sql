/****** Object:  View [dbo].[V_Old_Storage_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO







CREATE VIEW dbo.V_Old_Storage_Report
AS
SELECT T_Instrument_Name.IN_name AS Instrument, 
   V_old_storage.SP_vol_name_client + V_old_storage.SP_path AS [Storage Path]
FROM T_Instrument_Name INNER JOIN
   V_old_storage ON 
   T_Instrument_Name.IN_name = V_old_storage.SP_instrument_name
GO
GRANT VIEW DEFINITION ON [dbo].[V_Old_Storage_Report] TO [PNL\D3M578] AS [dbo]
GO
