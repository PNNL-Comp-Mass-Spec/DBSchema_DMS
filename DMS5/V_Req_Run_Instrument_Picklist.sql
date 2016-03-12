/****** Object:  View [dbo].[V_Req_Run_Instrument_Picklist] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create VIEW dbo.V_Req_Run_Instrument_Picklist
AS
SELECT DISTINCT 
    CASE WHEN (IN_name LIKE 'LCQ%') THEN 'LCQ' ELSE IN_name + ' ' + IN_usage END AS val, 
    CASE WHEN (IN_name LIKE 'LCQ%') THEN 'LCQ' ELSE IN_name END AS ex
FROM dbo.T_Instrument_Name
WHERE (NOT (IN_name LIKE 'SW_%')) AND 
      (IN_status = 'active') AND 
      (IN_operations_role <> 'QC')

GO
GRANT VIEW DEFINITION ON [dbo].[V_Req_Run_Instrument_Picklist] TO [PNL\D3M578] AS [dbo]
GO
