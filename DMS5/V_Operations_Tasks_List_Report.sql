/****** Object:  View [dbo].[V_Operations_Tasks_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Operations_Tasks_List_Report]
AS
SELECT  ID ,
        Tab ,
        Description ,
        Assigned_Personal AS [Assigned Personal] ,
        Comments ,
        Status ,
        Priority ,
        Hours_Spent,
        CASE WHEN Status IN ('Completed', 'Not Implemented') THEN DATEDIFF(DAY, Created, Closed) ELSE DATEDIFF(DAY, Created, GETDATE()) END  AS Days_In_Queue ,
        Work_Package ,
        Created,
        Closed,
      Case 
			When Status In ('Completed', 'Not Implemented') Then 0			-- Request is complete or closed
			When DATEDIFF(DAY, Created, GETDATE()) <= 30 Then	30	-- Request is 0 to 30 days old
			When DATEDIFF(DAY, Created, GETDATE()) <= 60 Then	60	-- Request is 30 to 60 days old
			When DATEDIFF(DAY, Created, GETDATE()) <= 90 Then	90	-- Request is 60 to 90 days old
			Else 120								-- Request is over 90 days old
		End
		AS #Age_Bracket    
FROM    T_Operations_Tasks

GO
GRANT VIEW DEFINITION ON [dbo].[V_Operations_Tasks_List_Report] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Operations_Tasks_List_Report] TO [PNL\D3M580] AS [dbo]
GO
