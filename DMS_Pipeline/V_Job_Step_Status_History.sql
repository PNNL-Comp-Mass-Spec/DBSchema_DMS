/****** Object:  View [dbo].[V_Job_Step_Status_History] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Job_Step_Status_History]
AS
SELECT PivotData.Posting_Time,
      IsNull([Waiting], 0) AS [Waiting],
		IsNull([Enabled], 0) AS [Enabled],
		IsNull([Running], 0) AS [Running],
		IsNull([Completed], 0) AS [Completed],
		IsNull([Failed], 0) AS [Failed],
		IsNull([Holding], 0) AS [Holding]
FROM ( SELECT CONVERT(smalldatetime, JSH.Posting_Time) AS Posting_time,
			   SSN.Name as StateName,
			   Step_Count
		FROM T_Job_Step_Status_History JSH
			 INNER JOIN T_Job_Step_State_Name SSN
			   ON JSH.State = SSN.ID
         ) AS SourceTable
     PIVOT ( Sum(Step_Count)
             FOR StateName
             IN ( [Waiting], [Enabled], [Running], [Completed], [Failed], [Holding] ) ) AS PivotData


GO
GRANT VIEW DEFINITION ON [dbo].[V_Job_Step_Status_History] TO [DDL_Viewer] AS [dbo]
GO
