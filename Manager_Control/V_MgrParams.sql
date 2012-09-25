/****** Object:  View [dbo].[V_MgrParams] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[V_MgrParams]
AS
SELECT dbo.T_Mgrs.M_ID AS ManagerID,
       dbo.T_Mgrs.M_Name AS ManagerName,
       dbo.T_MgrTypes.MT_TypeName AS ManagerType,
       dbo.T_ParamType.ParamName AS ParameterName,
       dbo.T_ParamValue.Value AS ParameterValue,
       dbo.T_ParamValue.Comment,
       dbo.T_ParamValue.Last_Affected,
       dbo.T_ParamValue.Entered_By
FROM dbo.T_Mgrs
     INNER JOIN dbo.T_MgrTypes
       ON dbo.T_Mgrs.M_TypeID = dbo.T_MgrTypes.MT_TypeID
     INNER JOIN dbo.T_ParamValue
       ON dbo.T_Mgrs.M_ID = dbo.T_ParamValue.MgrID
     INNER JOIN dbo.T_ParamType
       ON dbo.T_ParamValue.TypeID = dbo.T_ParamType.ParamID




GO
