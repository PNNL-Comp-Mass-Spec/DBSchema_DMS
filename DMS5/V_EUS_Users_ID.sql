/****** Object:  View [dbo].[V_EUS_Users_ID] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_EUS_Users_ID]
AS
SELECT PERSON_ID AS user_id,
       NAME_FM AS user_name,
       HID AS hanford_id,
       Name AS site_status,
       Valid As valid_eus_id
FROM T_EUS_Users U
     INNER JOIN T_EUS_Site_Status S
       ON U.Site_Status = S.ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_EUS_Users_ID] TO [DDL_Viewer] AS [dbo]
GO
