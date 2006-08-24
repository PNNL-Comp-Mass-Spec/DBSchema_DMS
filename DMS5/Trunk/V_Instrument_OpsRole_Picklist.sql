/****** Object:  View [dbo].[V_Instrument_OpsRole_Picklist] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create VIEW V_Instrument_OpsRole_Picklist
AS
SELECT DISTINCT IN_operations_role AS val
FROM         dbo.T_Instrument_Name

GO
