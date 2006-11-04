/****** Object:  View [dbo].[V_Run_Planning_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create VIEW dbo.V_Run_Planning_Report
AS
SELECT     TOP 100 PERCENT RA.Instrument, MIN(RA.Request) AS [Min Request], RA.[Work Package], RA.Proposal, RA.Requester, 
                      CASE WHEN RA.Batch = 0 THEN LEFT(RA.Experiment, 10) + CASE WHEN LEN(RA.Experiment) 
                      > 10 THEN '...' ELSE '' END ELSE RRB.Batch END AS [Batch/Experiment], MIN(CONVERT(datetime, FLOOR(CONVERT(float, RA.Created)))) 
                      AS [Date  Created], RA.Comment, COUNT(RA.Name) AS [Run Count]
FROM         dbo.V_Run_Assignment RA INNER JOIN
                      dbo.T_Requested_Run_Batches RRB ON RA.Batch = RRB.ID
GROUP BY RA.[Work Package], RA.Proposal, RA.Requester, RA.Comment, RA.Instrument, RRB.Batch, CASE WHEN RA.Batch = 0 THEN LEFT(RA.Experiment, 10) 
                      + CASE WHEN len(RA.Experiment) > 10 THEN '...' ELSE '' END ELSE RRB.Batch END
ORDER BY RA.Instrument, MIN(RA.Request)

GO
