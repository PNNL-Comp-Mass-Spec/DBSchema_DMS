/****** Object:  View [dbo].[V_Campaign_Cell_Culture_Tracking] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW dbo.V_Campaign_Cell_Culture_Tracking
AS
SELECT dbo.T_Cell_Culture.CC_Name AS [cell culture],
       dbo.T_Cell_Culture.CC_Reason AS reason,
       dbo.T_Cell_Culture.CC_Created AS created,
       dbo.T_Campaign.Campaign_Num AS campaign
FROM dbo.T_Campaign
     INNER JOIN dbo.T_Cell_Culture
       ON dbo.T_Campaign.Campaign_ID = dbo.T_Cell_Culture.CC_Campaign_ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Campaign_Cell_Culture_Tracking] TO [DDL_Viewer] AS [dbo]
GO
