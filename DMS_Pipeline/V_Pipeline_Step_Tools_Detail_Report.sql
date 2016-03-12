/****** Object:  View [dbo].[V_Pipeline_Step_Tools_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Pipeline_Step_Tools_Detail_Report]
AS
SELECT 
    ID AS [ID], 
    Name AS [Name], 
    Type AS [Type], 
    Description AS [Description], 
    Shared_Result_Version AS [Shared Result Version], 
    Filter_Version AS [Filter Version], 
    CPU_Load AS [CPU Load], 
    Memory_Usage_MB AS [Memory Usage MB],
    Parameter_Template AS [Parameter Template],
    Param_File_Storage_Path AS [Param File Storage Path]
FROM T_Step_Tools


GO
GRANT VIEW DEFINITION ON [dbo].[V_Pipeline_Step_Tools_Detail_Report] TO [PNL\D3M578] AS [dbo]
GO
