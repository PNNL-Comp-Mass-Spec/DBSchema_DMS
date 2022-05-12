/****** Object:  View [dbo].[V_Instrument_Status_Picklist] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Instrument_Status_Picklist]
AS
SELECT 'active' AS val
UNION
SELECT 'inactive' AS val
UNION
SELECT 'offline' AS val
UNION
SELECT 'broken' AS val

GO
GRANT VIEW DEFINITION ON [dbo].[V_Instrument_Status_Picklist] TO [DDL_Viewer] AS [dbo]
GO
