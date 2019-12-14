/****** Object:  View [dbo].[V_MgrParamDefaults] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_MgrParamDefaults]
AS
SELECT MTPM.MgrTypeID,
       MT.MT_TypeName AS ManagerType,
       MTPM.ParamTypeID AS [Param ID],
       PT.ParamName AS Param,
       MTPM.DefaultValue AS Value,
       IsNull(PT.PicklistName, '') AS PicklistName
FROM T_MgrType_ParamType_Map MTPM
     INNER JOIN T_ParamType PT
       ON MTPM.ParamTypeID = PT.ParamID
     INNER JOIN T_MgrTypes MT
       ON MTPM.MgrTypeID = MT.MT_TypeID

GO
