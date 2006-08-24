/****** Object:  View [dbo].[V_Cell_Culture_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW dbo.V_Cell_Culture_Entry
AS
SELECT dbo.T_Cell_Culture.CC_Name AS Name, 
   dbo.T_Cell_Culture.CC_Source_Name, 
   dbo.T_Cell_Culture.CC_Owner_PRN, 
   dbo.T_Cell_Culture.CC_PI_PRN, 
   dbo.T_Cell_Culture_Type_Name.Name AS CultureTypeName, 
   dbo.T_Cell_Culture.CC_Reason, 
   dbo.T_Cell_Culture.CC_Comment, 
   dbo.T_Campaign.Campaign_Num
FROM dbo.T_Cell_Culture INNER JOIN
   dbo.T_Cell_Culture_Type_Name ON 
   dbo.T_Cell_Culture.CC_Type = dbo.T_Cell_Culture_Type_Name.ID
    INNER JOIN
   dbo.T_Campaign ON 
   dbo.T_Cell_Culture.CC_Campaign_ID = dbo.T_Campaign.Campaign_ID
GO
