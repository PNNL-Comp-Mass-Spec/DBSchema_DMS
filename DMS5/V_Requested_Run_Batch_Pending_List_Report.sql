/****** Object:  View [dbo].[V_Requested_Run_Batch_Pending_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW dbo.V_Requested_Run_Batch_Pending_List_Report
AS
SELECT * 
FROM V_Requested_Run_Batch_List_Report
WHERE Requests > 0


GO
GRANT VIEW DEFINITION ON [dbo].[V_Requested_Run_Batch_Pending_List_Report] TO [PNL\D3M578] AS [dbo]
GO
