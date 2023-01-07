/****** Object:  View [dbo].[V_Data_Analysis_Request_Queue_Times] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Data_Analysis_Request_Queue_Times]
AS
SELECT request_id,
       created,
       state,
       closed,
       CASE
           WHEN State = 0 THEN NULL
           WHEN State IN (4) THEN DateDiff(DAY, Created, Closed)
           ELSE DateDiff(DAY, Created, ISNULL(Closed, GETDATE()))
       END AS days_in_queue,
       DateDiff(DAY, StateFirstEntered, GETDATE()) AS days_in_state
FROM ( SELECT R.ID AS Request_ID,
              R.Created,
              R.State,
              ClosedQ.Closed,
              StateEnteredQ.StateFirstEntered
       FROM T_Data_Analysis_Request R
            LEFT OUTER JOIN ( SELECT Request_ID,
                                     New_State_ID,
                                     MAX(Entered) AS Closed
                              FROM T_Data_Analysis_Request_Updates
                              WHERE (New_State_ID = 4 AND
                                     Old_State_ID <> 4) -- Closed
                              GROUP BY Request_ID, New_State_ID ) ClosedQ
              ON ClosedQ.Request_ID = R.ID
            LEFT OUTER JOIN ( SELECT Request_ID,
                                     New_State_ID AS State_ID,
                                     MIN(Entered) AS StateFirstEntered
                              FROM T_Data_Analysis_Request_Updates
                              GROUP BY Request_ID, New_State_ID ) StateEnteredQ
              ON StateEnteredQ.Request_ID = R.ID AND
                 StateEnteredQ.State_ID = R.State ) OuterQ


GO
GRANT VIEW DEFINITION ON [dbo].[V_Data_Analysis_Request_Queue_Times] TO [DDL_Viewer] AS [dbo]
GO
