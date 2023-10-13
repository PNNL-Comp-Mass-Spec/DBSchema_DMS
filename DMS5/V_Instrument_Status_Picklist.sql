/****** Object:  View [dbo].[V_Instrument_Status_Picklist] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Instrument_Status_Picklist]
AS
SELECT state_name AS val
FROM T_Instrument_State_Name

GO
GRANT VIEW DEFINITION ON [dbo].[V_Instrument_Status_Picklist] TO [DDL_Viewer] AS [dbo]
GO
