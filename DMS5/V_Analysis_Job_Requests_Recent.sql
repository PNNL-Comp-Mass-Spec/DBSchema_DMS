/****** Object:  View [dbo].[V_Analysis_Job_Requests_Recent] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Analysis_Job_Requests_Recent] 
AS
SELECT *
FROM V_Analysis_Job_Request_List_Report
WHERE State = 'new' OR
      Created >= DateAdd(day, -5, GetDate())


GO
GRANT VIEW DEFINITION ON [dbo].[V_Analysis_Job_Requests_Recent] TO [PNL\D3M578] AS [dbo]
GO
