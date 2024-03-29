/****** Object:  View [dbo].[V_Experiment_Date] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW dbo.V_Experiment_Date
AS
SELECT experiment_num,
       { fn YEAR(EX_created) } AS year,
       { fn MONTH(EX_created) } AS month,
       day(EX_created) AS day
FROM dbo.T_Experiments


GO
GRANT VIEW DEFINITION ON [dbo].[V_Experiment_Date] TO [DDL_Viewer] AS [dbo]
GO
