/****** Object:  View [dbo].[V_Sample_Prep_Request_Queue_Times] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Sample_Prep_Request_Queue_Times]
AS
SELECT request_id,
       created,
       state_id,
       complete_or_closed,
       CASE
           WHEN state_id = 0 THEN NULL
           WHEN state_id IN (4, 5) THEN DateDiff(DAY, Created, Complete_or_Closed)
           ELSE DateDiff(DAY, Created, ISNULL(Complete_or_Closed, GETDATE()))
       END AS days_in_queue,
       CASE
           WHEN state_id = 5 THEN NULL
           Else DateDiff(DAY, StateFirstEntered, GETDATE())
       End AS days_in_state
FROM ( SELECT SPR.ID AS Request_ID,
              SPR.Created,
              SPR.[state] AS state_id,
              CASE
                  WHEN PrepComplete IS NULL THEN Closed
                  WHEN Closed IS NULL THEN PrepComplete
                  WHEN PrepComplete < Closed THEN PrepComplete
                  ELSE Closed
              END AS Complete_or_Closed,
              ChangeQ.PrepComplete,
              ChangeQ.Closed,
              StateEnteredQ.StateFirstEntered
       FROM T_Sample_Prep_Request SPR
            LEFT OUTER JOIN ( SELECT Request_ID,
                                     pvt.[4] AS PrepComplete,
                                     pvt.[5] AS Closed
                              FROM (SELECT Request_ID,
                                           End_State_ID AS State_ID,
                                           MAX(Date_of_Change) AS Entered
                                    FROM T_Sample_Prep_Request_Updates
                                    WHERE (End_State_ID = 4 AND
                                           Beginning_State_ID <> 4)	-- Prep Complete
                                    GROUP BY Request_ID, End_State_ID
                                    UNION
                                    SELECT Request_ID,
                                           End_State_ID,
                                           MAX(Date_of_Change) AS Entered
                                    FROM T_Sample_Prep_Request_Updates
                                    WHERE (End_State_ID = 5 AND
                                           Beginning_State_ID <> 5) -- Closed
                                    GROUP BY Request_ID, End_State_ID
                                   ) Src
                                   PIVOT ( MAX(Entered)
                                           FOR State_ID
                                           IN ( [4], [5] )
                                   ) AS pvt
                            ) ChangeQ
              ON ChangeQ.Request_ID = SPR.ID
            LEFT OUTER JOIN ( SELECT Request_ID, End_State_ID As State_ID, MIN(Date_of_Change) As StateFirstEntered
                              FROM T_Sample_Prep_Request_Updates
                              GROUP BY Request_ID, End_State_ID
                            ) StateEnteredQ
              ON StateEnteredQ.Request_ID = SPR.ID And StateEnteredQ.State_ID = SPR.[state]
       ) OuterQ


GO
GRANT VIEW DEFINITION ON [dbo].[V_Sample_Prep_Request_Queue_Times] TO [DDL_Viewer] AS [dbo]
GO
