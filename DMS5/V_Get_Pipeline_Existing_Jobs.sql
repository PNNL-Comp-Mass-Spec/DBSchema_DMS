/****** Object:  View [dbo].[V_Get_Pipeline_Existing_Jobs] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Get_Pipeline_Existing_Jobs]
AS
SELECT AJ_jobID AS Job,
       AJ_StateID AS State
FROM dbo.T_Analysis_Job


GO
GRANT VIEW DEFINITION ON [dbo].[V_Get_Pipeline_Existing_Jobs] TO [DDL_Viewer] AS [dbo]
GO
