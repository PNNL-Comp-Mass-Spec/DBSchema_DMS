/****** Object:  View [dbo].[V_Param_Name_Picklist] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Param_Name_Picklist]
AS
SELECT ParamName AS val,
       ParamName AS ex,
       MgrTypeID AS M_TypeID
FROM T_ParamType
     Inner JOIN T_MgrType_ParamType_Map
       ON ParamID = ParamTypeID

GO
