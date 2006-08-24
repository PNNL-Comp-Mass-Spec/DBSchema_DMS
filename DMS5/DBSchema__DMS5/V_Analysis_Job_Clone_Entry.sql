/****** Object:  View [dbo].[V_Analysis_Job_Clone_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create VIEW V_Analysis_Job_Clone_Entry
AS
SELECT CONVERT(varchar(32), AJ_jobID) 
   AS JobNum,
   AJ_assignedProcessorName AS assignedProcessor, 
   AJ_comment AS Comment
FROM T_Analysis_Job 
   INNER JOIN T_Analysis_Tool ON AJ_analysisToolID = AJT_toolID

GO
GRANT SELECT ON [dbo].[V_Analysis_Job_Clone_Entry] TO [DMS_SP_User]
GO
GRANT SELECT ON [dbo].[V_Analysis_Job_Clone_Entry] ([JobNum]) TO [DMS_SP_User]
GO
GRANT SELECT ON [dbo].[V_Analysis_Job_Clone_Entry] ([assignedProcessor]) TO [DMS_SP_User]
GO
GRANT SELECT ON [dbo].[V_Analysis_Job_Clone_Entry] ([Comment]) TO [DMS_SP_User]
GO
