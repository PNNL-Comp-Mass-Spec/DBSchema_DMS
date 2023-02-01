/****** Object:  View [dbo].[V_Param_Name_Picklist] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Param_Name_Picklist]
AS
SELECT ParamName As val,
       ParamName As ex,
       MgrTypeID As mgr_type_id
FROM T_ParamType pt
     INNER JOIN T_MgrType_ParamType_Map mtpm
       ON pt.ParamID = mtpm.ParamTypeID


GO
