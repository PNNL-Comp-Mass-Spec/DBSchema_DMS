/****** Object:  View [dbo].[V_Experiment_Cell_Culture_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW dbo.V_Experiment_Cell_Culture_Report
AS
SELECT dbo.V_Experiment_Report.Experiment, 
   dbo.V_Experiment_Report.Researcher, 
   dbo.V_Experiment_Report.Organism, 
   dbo.V_Experiment_Report.Comment, 
   dbo.T_Cell_Culture.CC_Name AS [#Cell Culture]
FROM dbo.T_Experiment_Cell_Cultures INNER JOIN
   dbo.T_Cell_Culture ON 
   dbo.T_Experiment_Cell_Cultures.CC_ID = dbo.T_Cell_Culture.CC_ID
    INNER JOIN
   dbo.V_Experiment_Report ON 
   dbo.T_Experiment_Cell_Cultures.Exp_ID = dbo.V_Experiment_Report.#ID
GO
GRANT VIEW DEFINITION ON [dbo].[V_Experiment_Cell_Culture_Report] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Experiment_Cell_Culture_Report] TO [PNL\D3M580] AS [dbo]
GO
