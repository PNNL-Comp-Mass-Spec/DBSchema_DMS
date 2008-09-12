/****** Object:  View [dbo].[V_Settings_Files_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW V_Settings_Files_List_Report
AS
SELECT 
    ID AS [ID], 
    Analysis_Tool AS [Analysis Tool], 
    [File_Name] AS [File Name], 
    Description AS [Description], 
    Active AS [Active]
FROM T_Settings_Files

GO
