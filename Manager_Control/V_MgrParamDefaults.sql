/****** Object:  View [dbo].[V_MgrParamDefaults] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE View [dbo].[V_MgrParamDefaults]
As
select MgrTypeID, MT_TypeName as ManagerType, ParamTypeID as [Param ID], ParamName as Param, DefaultValue as Value, isnull(dbo.T_ParamType.PicklistName, '') as PicklistName
from T_MgrType_ParamType_Map 
     join T_ParamType on ParamTypeID = ParamID
     join T_MgrTypes on MgrTypeID = MT_TypeID

GO
