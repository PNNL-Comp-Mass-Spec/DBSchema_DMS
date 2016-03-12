/****** Object:  View [dbo].[V_Active_Requested_Runs] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[V_Active_Requested_Runs]
AS
SELECT *
FROM V_Requested_Run_List_Report_2
WHERE Status = 'Active'


GO
GRANT VIEW DEFINITION ON [dbo].[V_Active_Requested_Runs] TO [PNL\D3M578] AS [dbo]
GO
