/****** Object:  View [dbo].[V_Helper_Dataset_Capture_Job_Steps_Ckbx] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW V_Helper_Dataset_Capture_Job_Steps_Ckbx
AS
SELECT     J.Dataset, J.Job, S.Script, JSN.Name AS Job_State, J.Storage_Server, J.Instrument, J.Start, J.Finish
FROM         T_Jobs AS J INNER JOIN
                      T_Job_State_Name AS JSN ON J.State = JSN.ID INNER JOIN
                      T_Scripts AS S ON J.Script = S.Script
GO
