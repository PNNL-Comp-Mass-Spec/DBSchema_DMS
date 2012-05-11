/****** Object:  View [dbo].[V_Cell_Culture_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW dbo.V_Cell_Culture_Report
AS
SELECT dbo.T_Cell_Culture.CC_Name AS Name, 
   dbo.T_Cell_Culture.CC_Source_Name AS Source, 
   dbo.T_Cell_Culture.CC_Owner_PRN AS Contact, 
   dbo.T_Cell_Culture_Type_Name.Name AS Type, 
   dbo.T_Cell_Culture.CC_Reason AS Reason, 
   dbo.T_Cell_Culture.CC_Created AS Created, 
   dbo.T_Cell_Culture.CC_PI_PRN AS PI, 
   dbo.T_Cell_Culture.CC_Comment AS Comment, 
   dbo.T_Campaign.Campaign_Num AS Campaign, 
   dbo.T_Cell_Culture.CC_ID AS #ID
FROM dbo.T_Cell_Culture INNER JOIN
   dbo.T_Cell_Culture_Type_Name ON 
   dbo.T_Cell_Culture.CC_Type = dbo.T_Cell_Culture_Type_Name.ID
    INNER JOIN
   dbo.T_Campaign ON 
   dbo.T_Cell_Culture.CC_Campaign_ID = dbo.T_Campaign.Campaign_ID
GO
GRANT VIEW DEFINITION ON [dbo].[V_Cell_Culture_Report] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Cell_Culture_Report] TO [PNL\D3M580] AS [dbo]
GO
