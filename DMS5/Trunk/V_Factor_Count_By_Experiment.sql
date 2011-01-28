/****** Object:  View [dbo].[V_Factor_Count_By_Experiment] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Factor_Count_By_Experiment]
AS
SELECT Exp_ID,
       SUM(CASE WHEN Factor IS NULL THEN 0 ELSE 1 END) AS Factor_Count
FROM ( SELECT DISTINCT Exp.Exp_ID,
                       CASE WHEN DS.Exp_ID IS NULL 
                            THEN ExpRRFactor.Name
                            ELSE DSRRFactor.Name
                       END AS Factor
       FROM T_Experiments Exp
            LEFT OUTER JOIN T_Dataset DS
                            INNER JOIN T_Requested_Run DSRR
                              ON DS.Dataset_ID = DSRR.DatasetID
                            INNER JOIN T_Factor DSRRFactor
                              ON DSRR.ID = DSRRFactor.TargetID 
                                 AND
                                 DSRRFactor.TYPE = 'Run_Request'
              ON Exp.Exp_ID = DS.Exp_ID
            LEFT OUTER JOIN T_Factor ExpRRFactor
                            INNER JOIN T_Requested_Run ExpRR
                              ON ExpRRFactor.TargetID = ExpRR.ID 
                                 AND
                                 ExpRRFactor.TYPE = 'Run_Request'
              ON Exp.Exp_ID = ExpRR.Exp_ID ) ExperimentFactorQ
GROUP BY Exp_ID


GO
