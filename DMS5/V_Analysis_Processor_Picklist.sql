/****** Object:  View [dbo].[V_Analysis_Processor_Picklist] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create VIEW V_Analysis_Processor_Picklist
AS
SELECT DISTINCT TOP 100 PERCENT AJ_assignedProcessorName AS val, '' AS ex
FROM         dbo.T_Analysis_Job
WHERE     (AJ_assignedProcessorName IS NOT NULL) AND (AJ_StateID = 4) AND (DATEADD(Month, 12, AJ_created) > GETDATE())
ORDER BY val

GO
