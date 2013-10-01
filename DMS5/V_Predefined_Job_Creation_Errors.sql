/****** Object:  View [dbo].[V_Predefined_Job_Creation_Errors] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[V_Predefined_Job_Creation_Errors] as
SELECT SQ.Item,
       D.Dataset_Num AS Dataset,
       SQ.State,
       SQ.Result_Code,
       SQ.Message,
       SQ.Jobs_Created,
       SQ.Entered,
       SQ.Last_Affected
FROM T_Predefined_Analysis_Scheduling_Queue SQ
     INNER JOIN T_Dataset D
       ON SQ.Dataset_ID = D.Dataset_ID
WHERE Result_Code <> 0 AND
      SQ.State Not In ('Ignore') AND
      Last_Affected >= DATEADD(DAY, -14, GETDATE())	-- Report errors within the last 14 days



GO
GRANT VIEW DEFINITION ON [dbo].[V_Predefined_Job_Creation_Errors] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Predefined_Job_Creation_Errors] TO [PNL\D3M580] AS [dbo]
GO
