/****** Object:  View [dbo].[V_Mgr_Param_Defaults] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Mgr_Param_Defaults]
AS
SELECT MTPM.MgrTypeID As mgr_type_id,
       MT.MT_TypeName As manager_type,
       MTPM.ParamTypeID As param_id,
       PT.ParamName As param,
       MTPM.DefaultValue As value,
       IsNull(PT.PicklistName, '') As picklist_name
FROM T_MgrType_ParamType_Map MTPM
     INNER JOIN T_ParamType PT
       ON MTPM.ParamTypeID = PT.ParamID
     INNER JOIN T_MgrTypes MT
       ON MTPM.MgrTypeID = MT.MT_TypeID


GO
