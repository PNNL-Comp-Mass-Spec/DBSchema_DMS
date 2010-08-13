/****** Object:  View [dbo].[V_Run_Planning_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[V_Run_Planning_Report]
AS
SELECT Instrument,
       [Run Count],
       [Batch or Experiment],
       Requester,
       [Date Created],
       DATEDIFF(DAY, [Date Created], GETDATE()) AS [Days in Queue],
       [Separation Type],
       CASE
           WHEN LEN(RequestLookupQ.RDS_comment) > 30 THEN 
             SubString(RequestLookupQ.RDS_comment, 1, 27) + '...'
           ELSE RequestLookupQ.RDS_comment
       END AS [Comment],
       [Min Request],
       [Work Package],
       Proposal,
       Locked,
       [Last Ordered],
       [Request Name Code],
       Case 
			When DATEDIFF(DAY, [Date Created], GETDATE()) <= 30 Then	30	-- Request is 0 to 30 days old
			When DATEDIFF(DAY, [Date Created], GETDATE()) <= 60 Then	60	-- Request is 30 to 60 days old
			When DATEDIFF(DAY, [Date Created], GETDATE()) <= 90 Then	90	-- Request is 60 to 90 days old
			Else 120								-- Request is over 90 days old
		End
		AS #DaysInQueue
FROM ( SELECT Instrument,
              MIN(RequestID) AS [Min Request],
              COUNT(RequestName) AS [Run Count],
              MIN([Batch/Experiment]) AS [Batch or Experiment],
              Requester,
              MIN(Request_Created) AS [Date Created],
              [Separation Type],
              [Work Package],
              Proposal,
              Locked,
              [Last Ordered],
              [Request Name Code]
       FROM ( SELECT RA.Instrument,
                     RA.[Separation Type],
                     RA.Request AS RequestID,
                     RA.Name AS RequestName,
                     CASE WHEN RA.Batch = 0 THEN
						  LEFT(RA.Experiment, 20) +
								CASE WHEN LEN(RA.Experiment) > 20 
								THEN '...'
								ELSE ''
								END
                     ELSE 
					      LEFT(RRB.Batch, 20) +
								CASE WHEN LEN(RRB.Batch) > 20 
								THEN '...'
								ELSE ''
								END
                     END AS [Batch/Experiment],
                     RA.[Request Name Code],
                     RA.Requester,
                     RA.Created AS Request_Created,
                     RA.[Work Package],
                     RA.Proposal,
                     RRB.Locked,
                     CONVERT(datetime, FLOOR(CONVERT(float, RRB.Last_Ordered))) AS [Last Ordered]
              FROM dbo.V_Run_Assignment AS RA
                   INNER JOIN dbo.T_Requested_Run_Batches AS RRB
                     ON RA.Batch = RRB.ID
              WHERE (RA.Status = 'Active') 
           ) RequestQ
       GROUP BY Instrument, [Separation Type], [Request Name Code], Requester, 
                [Work Package], Proposal, Locked, [Last Ordered] 
    ) GroupQ
	INNER JOIN dbo.T_Requested_Run RequestLookupQ
       ON GroupQ.[Min Request] = RequestLookupQ.ID




GO
GRANT VIEW DEFINITION ON [dbo].[V_Run_Planning_Report] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Run_Planning_Report] TO [PNL\D3M580] AS [dbo]
GO
