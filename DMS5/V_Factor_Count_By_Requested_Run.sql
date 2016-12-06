/****** Object:  View [dbo].[V_Factor_Count_By_Requested_Run] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[V_Factor_Count_By_Requested_Run]
AS
SELECT RR_ID,
       SUM(CASE WHEN Factor IS NULL THEN 0 ELSE 1 END) AS Factor_Count
FROM ( SELECT DISTINCT RR.ID AS RR_ID,
                       RRFactor.Name AS Factor
       FROM T_Factor RRFactor
            INNER JOIN T_Requested_Run RR
              ON RRFactor.TargetID = RR.ID AND
                 RRFactor.TYPE = 'Run_Request' ) FactorQ
GROUP BY RR_ID



GO
GRANT VIEW DEFINITION ON [dbo].[V_Factor_Count_By_Requested_Run] TO [DDL_Viewer] AS [dbo]
GO
