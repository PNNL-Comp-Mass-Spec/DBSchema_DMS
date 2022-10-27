/****** Object:  View [dbo].[V_Biomaterial_Report_Ex] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Biomaterial_Report_Ex]
AS
SELECT dbo.V_Biomaterial_Report.Name,
   dbo.V_Biomaterial_Report.Source,
   dbo.V_Biomaterial_Report.Contact,
   dbo.V_Biomaterial_Report.Type,
   dbo.V_Biomaterial_Report.Reason,
   dbo.V_Biomaterial_Report.PI,
   dbo.V_Biomaterial_Report.Comment,
   dbo.V_Biomaterial_Report.Campaign,
   COUNT(dbo.T_Experiment_Cell_Cultures.CC_ID)
   AS [Exp. Count]
FROM dbo.V_Biomaterial_Report INNER JOIN
   dbo.T_Experiment_Cell_Cultures ON
   dbo.V_Biomaterial_Report.#id = dbo.T_Experiment_Cell_Cultures.CC_ID
GROUP BY dbo.V_Biomaterial_Report.Name,
   dbo.V_Biomaterial_Report.Source,
   dbo.V_Biomaterial_Report.PI, dbo.V_Biomaterial_Report.Type,
   dbo.V_Biomaterial_Report.Reason,
   dbo.V_Biomaterial_Report.Comment,
   dbo.V_Biomaterial_Report.Campaign,
   dbo.V_Biomaterial_Report.Contact


GO
GRANT VIEW DEFINITION ON [dbo].[V_Biomaterial_Report_Ex] TO [DDL_Viewer] AS [dbo]
GO
