/****** Object:  View [dbo].[V_AllMgrParamsByMgrType] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_AllMgrParamsByMgrType]
AS
SELECT DISTINCT TPT.MT_TypeID as ID, CASE WHEN PM.MgrTypeID IS NOT NULL THEN 'TRUE' ELSE '' END as Selected, TPT.ParamID, TPT.ParamName, TPT.Comment 
FROM (
		SELECT DISTINCT ParamID, ParamName, Comment, MT_TypeID, MT_TypeName
		FROM T_ParamType, T_MgrTypes
	 ) TPT
	left join T_MgrType_ParamType_Map PM on TPT.ParamID = PM.ParamTypeID and TPT.MT_TypeID = PM.MgrTypeID

GO
