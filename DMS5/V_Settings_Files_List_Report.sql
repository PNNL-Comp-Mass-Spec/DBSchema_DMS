/****** Object:  View [dbo].[V_Settings_Files_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[V_Settings_Files_List_Report]
AS
SELECT 
    ID AS [ID], 
    Analysis_Tool AS [Analysis Tool], 
    [File_Name] AS [File Name], 
    Description AS [Description], 
    Active AS [Active],
	Job_Usage_Count AS Jobs,
	MSGFPlus_AutoCentroid,
    HMS_AutoSupersede
FROM T_Settings_Files





GO
GRANT VIEW DEFINITION ON [dbo].[V_Settings_Files_List_Report] TO [DDL_Viewer] AS [dbo]
GO
