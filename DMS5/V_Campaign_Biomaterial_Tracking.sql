/****** Object:  View [dbo].[V_Campaign_Biomaterial_Tracking] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW dbo.V_Campaign_Biomaterial_Tracking
AS
SELECT dbo.T_Cell_Culture.CC_Name AS Biomaterial,
       dbo.T_Cell_Culture.CC_Reason AS Reason,
       dbo.T_Cell_Culture.CC_Created AS Created,
       dbo.T_Campaign.Campaign_Num AS campaign
FROM dbo.T_Campaign
     INNER JOIN dbo.T_Cell_Culture
       ON dbo.T_Campaign.Campaign_ID = dbo.T_Cell_Culture.CC_Campaign_ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Campaign_Biomaterial_Tracking] TO [DDL_Viewer] AS [dbo]
GO
