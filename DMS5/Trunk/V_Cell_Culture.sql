/****** Object:  View [dbo].[V_Cell_Culture] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW dbo.V_Cell_Culture
AS
SELECT dbo.T_Cell_Culture.CC_ID AS ID, 
   dbo.T_Cell_Culture.CC_Name AS Name, 
   dbo.T_Cell_Culture_Type_Name.Name AS Type, 
   dbo.T_Cell_Culture.CC_Reason AS Reason, 
   dbo.T_Cell_Culture.CC_Comment AS Comment, 
   dbo.T_Campaign.Campaign_Num AS Campaign
FROM dbo.T_Cell_Culture INNER JOIN
   dbo.T_Cell_Culture_Type_Name ON 
   dbo.T_Cell_Culture.CC_Type = dbo.T_Cell_Culture_Type_Name.ID
    INNER JOIN
   dbo.T_Campaign ON 
   dbo.T_Cell_Culture.CC_Campaign_ID = dbo.T_Campaign.Campaign_ID
GO
GRANT VIEW DEFINITION ON [dbo].[V_Cell_Culture] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Cell_Culture] TO [PNL\D3M580] AS [dbo]
GO
