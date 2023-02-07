/****** Object:  View [dbo].[V_DMS_Analysis_Job_Processor_Group_Association_Recent] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_DMS_Analysis_Job_Processor_Group_Association_Recent]
AS
SELECT Group_Name,
       Job,
       [State],
       Dataset,
       Tool,
       [Param File] AS Param_File,
       [Settings File] AS Settings_File
FROM S_DMS_V_Analysis_Job_Processor_Group_Association_Recent

GO
GRANT VIEW DEFINITION ON [dbo].[V_DMS_Analysis_Job_Processor_Group_Association_Recent] TO [DDL_Viewer] AS [dbo]
GO
