/****** Object:  View [dbo].[V_OldParamValue] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[V_OldParamValue] 
AS
SELECT M.M_Name,
       PT.ParamName,
       PV.Entry_ID,
       PV.TypeID,
       PV.Value,
       PV.MgrID,
       PV.Comment,
       PV.Last_Affected,
       PV.Entered_By,
       M.M_TypeID,
	   PT.ParamName as ParamType
FROM T_ParamValue_OldManagers PV
     INNER JOIN T_OldManagers M
       ON PV.MgrID = M.M_ID
     INNER JOIN T_ParamType PT
       ON PV.TypeID = PT.ParamID



GO
