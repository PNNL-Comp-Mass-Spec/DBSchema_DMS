/****** Object:  View [dbo].[V_Requested_Run_Batch_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[V_Requested_Run_Batch_Detail_Report]
AS
SELECT RRB.ID,
       RRB.Batch AS Name,
       RRB.Description,
       dbo.GetBatchRequestedRunList(RRB.ID) AS Requests,
       ISNULL(FC.Factor_Count, 0) AS Factors,
       U.Name_with_PRN AS [Owner],
       RRB.Created,
       RRB.Locked,
       RRB.Last_Ordered AS [Last Ordered],
       RRB.Requested_Batch_Priority AS [Requested Batch Priority],
       RRB.Requested_Completion_Date AS [Requested Completion Date],
       RRB.Justification_for_High_Priority AS [Justification for High Priority],
       dbo.GetBatchDatasetInstrumentList(RRB.ID) AS [Instrument Used],
       RRB.Requested_Instrument AS [Instrument Group],
       RRB.[Comment]
FROM dbo.T_Requested_Run_Batches RRB
     INNER JOIN dbo.T_Users U
       ON RRB.Owner = U.ID
     LEFT OUTER JOIN dbo.V_Factor_Count_By_Req_Run_Batch AS FC
       ON FC.Batch_ID = RRB.ID



GO
GRANT VIEW DEFINITION ON [dbo].[V_Requested_Run_Batch_Detail_Report] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Requested_Run_Batch_Detail_Report] TO [PNL\D3M580] AS [dbo]
GO
