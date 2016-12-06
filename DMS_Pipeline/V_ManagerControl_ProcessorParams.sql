/****** Object:  View [dbo].[V_ManagerControl_ProcessorParams] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_ManagerControl_ProcessorParams]
AS
SELECT MP.ManagerID, MP.ManagerName, MP.ManagerType, 
    MP.ParameterName, MP.ParameterValue
FROM ProteinSeqs.Manager_Control.dbo.V_MgrParams MP

GO
GRANT VIEW DEFINITION ON [dbo].[V_ManagerControl_ProcessorParams] TO [DDL_Viewer] AS [dbo]
GO
