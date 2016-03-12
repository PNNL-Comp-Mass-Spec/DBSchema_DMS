/****** Object:  View [dbo].[V_Req_Run_Instrument_Picklist_Ex] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create VIEW dbo.V_Req_Run_Instrument_Picklist_Ex
AS
SELECT IN_name AS val, '' AS ex
FROM T_Instrument_Name
WHERE (NOT (IN_name LIKE 'SW_%')) AND 
      (IN_status = 'active') AND 
      (IN_operations_role <> 'QC')
UNION
SELECT 'LCQ' AS val, '' AS ex

GO
GRANT VIEW DEFINITION ON [dbo].[V_Req_Run_Instrument_Picklist_Ex] TO [PNL\D3M578] AS [dbo]
GO
