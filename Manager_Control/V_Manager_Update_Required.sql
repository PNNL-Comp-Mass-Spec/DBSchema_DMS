/****** Object:  View [dbo].[V_Manager_Update_Required] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Manager_Update_Required]
AS
SELECT dbo.T_Mgrs.M_Name,
       dbo.T_ParamType.ParamName,
       dbo.T_ParamValue.Value
FROM dbo.T_Mgrs
     INNER JOIN dbo.T_ParamValue
       ON dbo.T_Mgrs.M_ID = dbo.T_ParamValue.MgrID
     INNER JOIN dbo.T_ParamType
       ON dbo.T_ParamValue.TypeID = dbo.T_ParamType.ParamID
WHERE (dbo.T_ParamType.ParamName = 'ManagerUpdateRequired')


GO
