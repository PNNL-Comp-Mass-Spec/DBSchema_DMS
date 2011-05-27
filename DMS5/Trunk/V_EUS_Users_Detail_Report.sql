/****** Object:  View [dbo].[V_EUS_Users_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[V_EUS_Users_Detail_Report]
AS
SELECT U.PERSON_ID AS ID,
       U.NAME_FM AS Name,
       SS.Name AS [Site Status],
       U.Last_Affected
FROM T_EUS_Users U
     INNER JOIN T_EUS_Site_Status SS
       ON U.Site_Status = SS.ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_EUS_Users_Detail_Report] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_EUS_Users_Detail_Report] TO [PNL\D3M580] AS [dbo]
GO
