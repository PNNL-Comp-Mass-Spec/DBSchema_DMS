/****** Object:  View [dbo].[V_Pipeline_Step_Tools_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[V_Pipeline_Step_Tools_List_Report]
AS
SELECT Name AS [Name],
       Type AS [Type],
       Description AS [Description],
       Shared_Result_Version AS [Shared Result Version],
       Filter_Version AS [Filter Version],
       CPU_Load AS [CPU Load],
       Memory_Usage_MB AS [Memory Usage MB],
       ID
FROM dbo.T_Step_Tools


GO
GRANT VIEW DEFINITION ON [dbo].[V_Pipeline_Step_Tools_List_Report] TO [DDL_Viewer] AS [dbo]
GO
