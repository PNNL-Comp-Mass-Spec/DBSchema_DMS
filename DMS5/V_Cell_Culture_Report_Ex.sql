/****** Object:  View [dbo].[V_Cell_Culture_Report_Ex] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW dbo.V_Cell_Culture_Report_Ex
AS
SELECT dbo.V_Cell_Culture_Report.Name, 
   dbo.V_Cell_Culture_Report.Source, 
   dbo.V_Cell_Culture_Report.Contact, 
   dbo.V_Cell_Culture_Report.Type, 
   dbo.V_Cell_Culture_Report.Reason, 
   dbo.V_Cell_Culture_Report.PI, 
   dbo.V_Cell_Culture_Report.Comment, 
   dbo.V_Cell_Culture_Report.Campaign, 
   COUNT(dbo.T_Experiment_Cell_Cultures.CC_ID) 
   AS [Exp. Count]
FROM dbo.V_Cell_Culture_Report INNER JOIN
   dbo.T_Experiment_Cell_Cultures ON 
   dbo.V_Cell_Culture_Report.#ID = dbo.T_Experiment_Cell_Cultures.CC_ID
GROUP BY dbo.V_Cell_Culture_Report.Name, 
   dbo.V_Cell_Culture_Report.Source, 
   dbo.V_Cell_Culture_Report.PI, dbo.V_Cell_Culture_Report.Type, 
   dbo.V_Cell_Culture_Report.Reason, 
   dbo.V_Cell_Culture_Report.Comment, 
   dbo.V_Cell_Culture_Report.Campaign, 
   dbo.V_Cell_Culture_Report.Contact
GO
GRANT VIEW DEFINITION ON [dbo].[V_Cell_Culture_Report_Ex] TO [PNL\D3M578] AS [dbo]
GO
