/****** Object:  View [dbo].[V_Get_Pipeline_Job_Priority] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Get_Pipeline_Job_Priority]
AS
SELECT AJ.AJ_jobID AS job,
       AJ.AJ_priority AS priority
FROM dbo.T_Analysis_Job AS AJ
WHERE (AJ.AJ_StateID IN (1, 2, 8))


GO
GRANT VIEW DEFINITION ON [dbo].[V_Get_Pipeline_Job_Priority] TO [DDL_Viewer] AS [dbo]
GO
