/****** Object:  View [dbo].[V_ManagerControl_ProcessorParams] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_ManagerControl_ProcessorParams]
AS
SELECT MP.Manager_ID, MP.Manager_Name, MP.Manager_Type, 
    MP.Parameter_Name, MP.Parameter_Value
FROM s_mc_v_mgr_params MP

GO
GRANT VIEW DEFINITION ON [dbo].[V_ManagerControl_ProcessorParams] TO [DDL_Viewer] AS [dbo]
GO
