/****** Object:  View [dbo].[V_Instrument_Picklist] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Instrument_Picklist
AS
SELECT     IN_name + ' ' + IN_usage AS val, IN_name AS ex
FROM         dbo.T_Instrument_Name
WHERE     (NOT (IN_name LIKE 'SW_%')) AND (IN_status = 'active') AND (IN_operations_role <> 'QC')

GO
GRANT SELECT ON [dbo].[V_Instrument_Picklist] TO [DMS_LCMSNet_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Instrument_Picklist] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Instrument_Picklist] TO [PNL\D3M580] AS [dbo]
GO
