/****** Object:  View [dbo].[V_Settings_Files_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW V_Settings_Files_Entry
AS
SELECT 
    ID AS ID, 
    Analysis_Tool AS AnalysisTool, 
    [File_Name] AS FileName, 
    Description AS Description, 
    Active AS Active, 
    Contents AS Contents
FROM T_Settings_Files

GO
GRANT VIEW DEFINITION ON [dbo].[V_Settings_Files_Entry] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Settings_Files_Entry] TO [PNL\D3M580] AS [dbo]
GO
