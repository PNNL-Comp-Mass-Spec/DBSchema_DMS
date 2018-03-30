/****** Object:  View [dbo].[V_Pipeline_Step_Tools_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Pipeline_Step_Tools_Detail_Report]
AS
SELECT ID AS [ID],
       Name AS [Name],
       TYPE AS [Type],
       Description AS [Description],
       [Comment],
       Shared_Result_Version AS [Shared Result Version],
       Filter_Version AS [Filter Version],
       CPU_Load AS [CPU Load],
       Uses_All_Cores,
       Memory_Usage_MB AS [Memory Usage MB],
       Available_For_General_Processing,
       Param_File_Storage_Path AS [Param File Storage Path],
       Parameter_Template AS [Parameter Template],
       Tag,
       AvgRuntime_Minutes,
       Disable_Output_Folder_Name_Override_on_Skip,
       Primary_Step_Tool,
       Holdoff_Interval_Minutes
FROM T_Step_Tools

GO
GRANT VIEW DEFINITION ON [dbo].[V_Pipeline_Step_Tools_Detail_Report] TO [DDL_Viewer] AS [dbo]
GO
