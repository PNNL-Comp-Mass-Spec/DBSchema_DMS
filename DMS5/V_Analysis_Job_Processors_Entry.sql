/****** Object:  View [dbo].[V_Analysis_Job_Processors_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Analysis_Job_Processors_Entry
AS
SELECT id,
       state,
       processor_name,
       machine,
       notes,
       dbo.get_aj_processor_analysis_tool_list(ID) AS analysis_tools_list
FROM dbo.T_Analysis_Job_Processors

GO
GRANT VIEW DEFINITION ON [dbo].[V_Analysis_Job_Processors_Entry] TO [DDL_Viewer] AS [dbo]
GO
