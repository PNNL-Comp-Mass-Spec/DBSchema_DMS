/****** Object:  View [dbo].[V_Predefined_Job_Creation_Errors] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[V_Predefined_Job_Creation_Errors] as
SELECT Item,
       Dataset_Num AS Dataset,
       [State],
       Result_Code,
       [Message],
       Jobs_Created,
       Entered,
       Last_Affected
FROM T_Predefined_Analysis_Scheduling_Queue
WHERE Result_Code <> 0 AND
      Last_Affected >= DATEADD(DAY, -14, GETDATE())	-- Report errors within the last 14 days




GO
