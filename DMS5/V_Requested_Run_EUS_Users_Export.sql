/****** Object:  View [dbo].[V_Requested_Run_EUS_Users_Export] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Requested_Run_EUS_Users_Export] 
AS
SELECT RRUsers.Request_ID,
       RRUsers.EUS_Person_ID,
       RR.RDS_Name AS Request_Name,
       EUSUsers.NAME_FM AS EUS_User_Name
FROM T_Requested_Run_EUS_Users RRUsers
     INNER JOIN T_Requested_Run RR
       ON RRUsers.Request_ID = RR.ID
     INNER JOIN T_EUS_Users EUSUsers
       ON RRUsers.EUS_Person_ID = EUSUsers.PERSON_ID


GO
