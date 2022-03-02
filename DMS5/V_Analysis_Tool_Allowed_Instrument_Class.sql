/****** Object:  View [dbo].[V_Analysis_Tool_Allowed_Instrument_Class] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Analysis_Tool_Allowed_Instrument_Class]
AS
SELECT AIC.Analysis_Tool_ID,
       AIC.Instrument_Class,
       AIC.[Comment],
       AnalysisTool.AJT_toolName AS Tool_Name,
       AnalysisTool.AJT_toolBasename As Tool_Base_Name,
       AnalysisTool.AJT_resultType As Result_Type,
       AnalysisTool.AJT_active AS Tool_Active
FROM T_Analysis_Tool_Allowed_Instrument_Class AIC
     INNER JOIN T_Analysis_Tool AnalysisTool
       ON AIC.Analysis_Tool_ID = AnalysisTool.AJT_toolID


GO
