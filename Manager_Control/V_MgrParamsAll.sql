/****** Object:  View [dbo].[V_MgrParamsAll] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[V_MgrParamsAll]
AS
SELECT dbo.T_Mgrs.M_ID AS [Manager ID],
       dbo.T_Mgrs.M_Name AS Manager,
       dbo.T_MgrTypes.MT_TypeName AS [Manager Type],
       dbo.T_ParamType.ParamID AS [Param ID],
       dbo.T_ParamType.ParamName AS Param,
       dbo.T_ParamValue.Value,
       isnull(dbo.T_ParamType.PicklistName, '') AS PicklistName,
       dbo.T_ParamValue.Comment,
       dbo.T_ParamValue.Last_Affected,
       dbo.T_ParamValue.Entered_By
FROM dbo.T_MgrType_ParamType_Map
     INNER JOIN dbo.T_Mgrs
       ON dbo.T_MgrType_ParamType_Map.MgrTypeID = dbo.T_Mgrs.M_TypeID
     INNER JOIN dbo.T_MgrTypes
       ON dbo.T_Mgrs.M_TypeID = dbo.T_MgrTypes.MT_TypeID
     INNER JOIN dbo.T_ParamType
       ON dbo.T_MgrType_ParamType_Map.ParamTypeID = dbo.T_ParamType.ParamID
     LEFT OUTER JOIN dbo.T_ParamValue
       ON dbo.T_Mgrs.M_ID = dbo.T_ParamValue.MgrID AND
          dbo.T_ParamType.ParamID = dbo.T_ParamValue.TypeID



GO
