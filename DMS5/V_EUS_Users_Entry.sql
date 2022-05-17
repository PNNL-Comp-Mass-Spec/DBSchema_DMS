/****** Object:  View [dbo].[V_EUS_Users_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_EUS_Users_Entry]
AS
SELECT PERSON_ID AS id,
       NAME_FM AS name,
       HID AS hanford_id,
       site_status
FROM T_EUS_Users


GO
GRANT VIEW DEFINITION ON [dbo].[V_EUS_Users_Entry] TO [DDL_Viewer] AS [dbo]
GO
