/****** Object:  View [dbo].[V_Capture_Jobs_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Capture_Jobs_Detail_Report
AS
SELECT     J.Job, J.Priority, J.Script, JSN.Name AS Job_State_B, 'Steps' AS Steps, J.Dataset, J.Dataset_ID AS [Dataset ID], J.Results_Folder_Name, J.Imported, 
                      J.Finish, J.Storage_Server, J.Instrument, J.Instrument_Class, J.Max_Simultaneous_Captures, J.Comment, dbo.GetJobParamList(J.Job) 
                      AS Parameters
FROM         dbo.T_Jobs AS J INNER JOIN
                      dbo.T_Job_State_Name AS JSN ON J.State = JSN.ID

GO
