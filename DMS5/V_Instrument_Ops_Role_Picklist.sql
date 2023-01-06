/****** Object:  View [dbo].[V_Instrument_Ops_Role_Picklist] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW V_Instrument_Ops_Role_Picklist
AS
SELECT DISTINCT IN_operations_role AS val
FROM dbo.T_Instrument_Name


GO
GRANT VIEW DEFINITION ON [dbo].[V_Instrument_Ops_Role_Picklist] TO [DDL_Viewer] AS [dbo]
GO
