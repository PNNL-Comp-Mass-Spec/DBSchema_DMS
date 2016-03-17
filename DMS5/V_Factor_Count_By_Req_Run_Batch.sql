/****** Object:  View [dbo].[V_Factor_Count_By_Req_Run_Batch] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[V_Factor_Count_By_Req_Run_Batch]
AS
SELECT Batch_ID,
       SUM(CASE WHEN Factor IS NULL THEN 0 ELSE 1 END) AS Factor_Count
FROM ( SELECT DISTINCT RRB.ID AS Batch_ID,
                       RRFactor.Name AS Factor
       FROM T_Factor RRFactor
            INNER JOIN T_Requested_Run RR
              ON RRFactor.TargetID = RR.ID AND
                 RRFactor.TYPE = 'Run_Request'
            INNER JOIN T_Requested_Run_Batches RRB
              ON RR.RDS_BatchID = RRB.ID ) FactorQ
GROUP BY Batch_ID



GO
GRANT VIEW DEFINITION ON [dbo].[V_Factor_Count_By_Req_Run_Batch] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Factor_Count_By_Req_Run_Batch] TO [PNL\D3M580] AS [dbo]
GO
