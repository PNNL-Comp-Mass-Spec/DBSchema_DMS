/****** Object:  View [dbo].[V_All_Mgr_Params_By_Mgr_Type] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_All_Mgr_Params_By_Mgr_Type]
AS
SELECT DISTINCT TPT.MT_TypeID AS id,
                CASE
                    WHEN PM.MgrTypeID IS NOT NULL THEN 'TRUE'
                    ELSE ''
                END AS selected,
                TPT.ParamID As param_id,
                TPT.ParamName As param_name,
                TPT.comment
FROM ( SELECT DISTINCT ParamID,
                       ParamName,
                       Comment,
                       MT_TypeID,
                       MT_TypeName
       FROM T_ParamType,
            T_MgrTypes ) TPT
     LEFT JOIN T_MgrType_ParamType_Map PM
       ON TPT.ParamID = PM.ParamTypeID AND
          TPT.MT_TypeID = PM.MgrTypeID


GO
