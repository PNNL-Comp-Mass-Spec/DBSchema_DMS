/****** Object:  View [dbo].[V_Biomaterial] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Biomaterial]
AS
SELECT dbo.T_Cell_Culture.CC_ID AS id, dbo.T_Cell_Culture.CC_Name AS name, dbo.T_Cell_Culture_Type_Name.Name AS type, dbo.T_Cell_Culture.CC_Reason AS reason,
       dbo.T_Cell_Culture.CC_Created AS created, dbo.T_Cell_Culture.CC_Comment AS comment, dbo.T_Campaign.Campaign_Num AS campaign
FROM dbo.T_Cell_Culture INNER JOIN
     dbo.T_Cell_Culture_Type_Name ON dbo.T_Cell_Culture.CC_Type = dbo.T_Cell_Culture_Type_Name.ID INNER JOIN
     dbo.T_Campaign ON dbo.T_Cell_Culture.CC_Campaign_ID = dbo.T_Campaign.Campaign_ID


GO
