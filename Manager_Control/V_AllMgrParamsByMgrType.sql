/****** Object:  View [dbo].[V_AllMgrParamsByMgrType] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_AllMgrParamsByMgrType]
AS
SELECT DISTINCT TPT.MT_TypeID AS ID,
                CASE
                    WHEN PM.MgrTypeID IS NOT NULL THEN 'TRUE'
                    ELSE ''
                END AS Selected,
                TPT.ParamID,
                TPT.ParamName,
                TPT.Comment
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
