/****** Object:  View [dbo].[V_Instrument_Picklist] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Instrument_Picklist]
AS
SELECT IN_name + ' ' + IN_usage AS val,
       IN_name AS ex
FROM dbo.T_Instrument_Name
WHERE NOT IN_name LIKE 'SW_%' AND
      IN_status IN ('Active', 'Offline', 'PrepHPLC') AND
      IN_operations_role <> 'QC'

GO
GRANT VIEW DEFINITION ON [dbo].[V_Instrument_Picklist] TO [DDL_Viewer] AS [dbo]
GO
GRANT SELECT ON [dbo].[V_Instrument_Picklist] TO [DMS_LCMSNet_User] AS [dbo]
GO
