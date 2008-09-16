/****** Object:  View [dbo].[V_Run_Planning_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Run_Planning_Report
AS
SELECT Instrument,
       MIN([Min Request]) AS [Min Request],
       SUM([Run Count]) AS [Run Count],
       [Batch/Experiment] AS [Batch or Experiment],
       Requester,
       MIN([Date Created]) AS [Date Created],
       [Separation Type],
       MIN(Comment) AS Comment,
       [Work Package],
       Proposal,
       Locked,
       [Last Ordered]
FROM ( SELECT RA.Instrument,
              RA.[Separation Type],
              MIN(RA.Request) AS [Min Request],
              COUNT(RA.Name) AS [Run Count],
              CASE WHEN RA.Batch = 0 OR LEFT(RRB.Batch, 4) <> LEFT(RA.Experiment, 4) 
              THEN LEFT(RA.Experiment, 10) +
                    CASE WHEN LEN(RA.Experiment) > 10 
                    THEN '...'
                    ELSE ''
                    END
              ELSE RRB.Batch
              END AS [Batch/Experiment],
              RA.Requester,
              MIN(CONVERT(datetime, FLOOR(CONVERT(float, RA.Created)))) AS [Date Created],
              MIN(CASE WHEN LEN(RA.Comment) > 30 THEN SubString(RA.Comment, 1, 27) + '...' ELSE RA.Comment END) AS Comment,
              RA.[Work Package],
              RA.Proposal,
              RRB.Locked,
              CONVERT(datetime, FLOOR(CONVERT(float, RRB.Last_Ordered))) AS [Last Ordered]
       FROM dbo.V_Run_Assignment AS RA
            INNER JOIN dbo.T_Requested_Run_Batches AS RRB
              ON RA.Batch = RRB.ID
       GROUP BY RA.Instrument, RA.[Separation Type], RRB.Batch, RA.Requester, 
                RA.[Work Package], RA.Proposal, RRB.Locked, 
              CASE WHEN RA.Batch = 0 OR LEFT(RRB.Batch, 4) <> LEFT(RA.Experiment, 4) 
              THEN LEFT(RA.Experiment, 10) +
                    CASE WHEN LEN(RA.Experiment) > 10 
                    THEN '...'
                    ELSE ''
                    END
              ELSE RRB.Batch
              END, 
              CONVERT(datetime, FLOOR(CONVERT(float, RRB.Last_Ordered))) 
     ) AS SrcDataQ
GROUP BY Instrument, [Batch/Experiment], Requester, [Separation Type], [Work Package], Proposal, Locked, [Last Ordered]

GO
