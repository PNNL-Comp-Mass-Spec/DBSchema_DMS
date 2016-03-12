/****** Object:  View [dbo].[V_EUS_Users_ID] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_EUS_Users_ID]
AS
SELECT PERSON_ID AS [User ID],
       NAME_FM AS [User Name],
       HID AS Hanford_ID,
       Name AS [Site Status]
FROM T_EUS_Users U
     INNER JOIN T_EUS_Site_Status S
       ON U.Site_Status = S.ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_EUS_Users_ID] TO [PNL\D3M578] AS [dbo]
GO
