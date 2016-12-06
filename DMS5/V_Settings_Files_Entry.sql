/****** Object:  View [dbo].[V_Settings_Files_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Settings_Files_Entry]
AS
SELECT ID,
       Analysis_Tool AS AnalysisTool,
       File_Name AS FileName,
       Description,
       Active,
       CONVERT(varchar(MAX), Contents) AS Contents,
       HMS_AutoSupersede
FROM dbo.T_Settings_Files



GO
GRANT VIEW DEFINITION ON [dbo].[V_Settings_Files_Entry] TO [DDL_Viewer] AS [dbo]
GO
