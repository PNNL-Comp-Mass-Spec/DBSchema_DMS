/****** Object:  View [dbo].[V_ParamValue] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[V_ParamValue] 
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
       M.M_TypeID
FROM T_ParamValue PV
     INNER JOIN T_Mgrs M
       ON PV.MgrID = M.M_ID
     INNER JOIN T_ParamType PT
       ON PV.TypeID = PT.ParamID



GO
