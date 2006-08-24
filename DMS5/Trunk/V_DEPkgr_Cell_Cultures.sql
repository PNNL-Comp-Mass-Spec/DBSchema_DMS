/****** Object:  View [dbo].[V_DEPkgr_Cell_Cultures] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_DEPkgr_Cell_Cultures
AS
SELECT     dbo.T_Cell_Culture.CC_ID AS Culture_ID, dbo.T_Cell_Culture.CC_Name AS Biomaterial_Source_Name, 
                      dbo.T_Cell_Culture.CC_Reason AS Reason_For_Preparation, dbo.T_Cell_Culture.CC_Comment AS Comments, 
                      dbo.T_Cell_Culture.CC_Source_Name AS Material_Source, Owner_Names.U_Name AS Owner_Name, PI_Names.U_Name AS PI_Name, 
                      dbo.T_Cell_Culture.CC_Campaign_ID AS Campaign_ID, dbo.T_Campaign.Campaign_Num AS Campaign_Name
FROM         dbo.T_Cell_Culture LEFT OUTER JOIN
                      dbo.T_Campaign ON dbo.T_Cell_Culture.CC_Campaign_ID = dbo.T_Campaign.Campaign_ID LEFT OUTER JOIN
                      dbo.T_Users PI_Names ON dbo.T_Cell_Culture.CC_PI_PRN = PI_Names.U_PRN LEFT OUTER JOIN
                      dbo.T_Users Owner_Names ON dbo.T_Cell_Culture.CC_Owner_PRN = Owner_Names.U_PRN

GO
