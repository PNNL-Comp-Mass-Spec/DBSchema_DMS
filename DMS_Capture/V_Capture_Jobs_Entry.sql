/****** Object:  View [dbo].[V_Capture_Jobs_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE view V_Capture_Jobs_Entry as         
SELECT  dbo.T_Jobs.job ,
        dbo.T_Jobs.priority ,
        dbo.T_Jobs.Script AS scriptName ,
        dbo.T_Jobs.Results_Folder_Name AS resultsFolderName ,
        dbo.T_Jobs.comment ,
        CONVERT(VARCHAR(MAX), dbo.T_Job_Parameters.Parameters) AS jobParam
FROM    dbo.T_Jobs
        INNER JOIN dbo.T_Job_Parameters ON dbo.T_Jobs.Job = dbo.T_Job_Parameters.Job       
GO
