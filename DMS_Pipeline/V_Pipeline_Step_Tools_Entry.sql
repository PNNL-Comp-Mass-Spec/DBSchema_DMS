/****** Object:  View [dbo].[V_Pipeline_Step_Tools_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Pipeline_Step_Tools_Entry]
AS
SELECT ID AS ID,
       Name AS [Name],
       Type AS [Type],
       Description AS [Description],
       Shared_Result_Version AS SharedResultVersion,
       Filter_Version AS FilterVersion,
       CPU_Load AS CPULoad,
       Memory_Usage_MB AS MemoryUsageMB,
       Parameter_Template AS ParameterTemplate,
       Param_File_Storage_Path AS ParamFileStoragePath
FROM T_Step_Tools


GO
GRANT VIEW DEFINITION ON [dbo].[V_Pipeline_Step_Tools_Entry] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Pipeline_Step_Tools_Entry] TO [PNL\D3M580] AS [dbo]
GO
