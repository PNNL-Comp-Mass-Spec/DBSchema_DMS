/****** Object:  View [dbo].[V_Pipeline_Step_Tools_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Pipeline_Step_Tools_List_Report]
AS
SELECT name,
       type,
       description,
       shared_result_version,
       filter_version,
       cpu_load,
       memory_usage_mb,
       id
FROM dbo.T_Step_Tools


GO
GRANT VIEW DEFINITION ON [dbo].[V_Pipeline_Step_Tools_List_Report] TO [DDL_Viewer] AS [dbo]
GO
