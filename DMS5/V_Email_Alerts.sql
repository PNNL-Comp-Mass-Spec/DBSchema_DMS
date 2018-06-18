/****** Object:  View [dbo].[V_Email_Alerts] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW V_Email_Alerts
AS
SELECT Alerts.ID,
       Alerts.Posted_by,
       Alerts.Posting_Time,
       Alerts.Alert_Type,
       Alerts.Message,
       Alerts.Recipients,
       Alerts.Alert_State,
       AlertState.Alert_State_Name,
       Alerts.Last_Affected
FROM T_Email_Alerts Alerts
     INNER JOIN T_Email_Alert_State AlertState
       ON Alerts.Alert_State = AlertState.Alert_State


GO
