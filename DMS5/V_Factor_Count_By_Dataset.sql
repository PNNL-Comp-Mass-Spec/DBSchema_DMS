/****** Object:  View [dbo].[V_Factor_Count_By_Dataset] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Factor_Count_By_Dataset]
AS
SELECT Dataset_ID,
       SUM(CASE WHEN Factor IS NULL THEN 0 ELSE 1 END) AS Factor_Count
FROM ( SELECT DISTINCT DS.Dataset_ID,
                       DSRRFactor.Name AS Factor
       FROM T_Factor DSRRFactor
            INNER JOIN T_Requested_Run DSRR
              ON DSRRFactor.TargetID = DSRR.ID
            RIGHT OUTER JOIN T_Dataset DS
              ON DSRRFactor.TYPE = 'Run_Request' AND
                 DSRR.DatasetID = DS.Dataset_ID ) FactorQ
GROUP BY Dataset_ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Factor_Count_By_Dataset] TO [DDL_Viewer] AS [dbo]
GO
