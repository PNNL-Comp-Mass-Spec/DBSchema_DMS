/****** Object:  View [dbo].[V_Cell_Culture_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Cell_Culture_Detail_Report
AS
SELECT     dbo.T_Cell_Culture.CC_Name AS Name, dbo.T_Cell_Culture.CC_Source_Name AS Source, 
                      dbo.T_Users.U_Name + ' (' + dbo.T_Cell_Culture.CC_Owner_PRN + ')' AS [Source Contact], 
                      dbo.V_Users.U_Name + ' (' + dbo.T_Cell_Culture.CC_PI_PRN + ')' AS PI, dbo.T_Cell_Culture_Type_Name.Name AS Type, 
                      dbo.T_Cell_Culture.CC_Reason AS Reason, dbo.T_Cell_Culture.CC_Comment AS Comment, dbo.T_Campaign.Campaign_Num AS Campaign, 
                      dbo.T_Cell_Culture.CC_ID AS ID, dbo.T_Material_Containers.Tag AS Container, dbo.T_Material_Locations.Tag AS Location, 
                      dbo.T_Cell_Culture.CC_Material_Active AS [Material Status]
FROM         dbo.T_Cell_Culture INNER JOIN
                      dbo.T_Cell_Culture_Type_Name ON dbo.T_Cell_Culture.CC_Type = dbo.T_Cell_Culture_Type_Name.ID INNER JOIN
                      dbo.T_Campaign ON dbo.T_Cell_Culture.CC_Campaign_ID = dbo.T_Campaign.Campaign_ID INNER JOIN
                      dbo.T_Material_Containers ON dbo.T_Cell_Culture.CC_Container_ID = dbo.T_Material_Containers.ID INNER JOIN
                      dbo.T_Material_Locations ON dbo.T_Material_Containers.Location_ID = dbo.T_Material_Locations.ID LEFT OUTER JOIN
                      dbo.T_Users ON dbo.T_Cell_Culture.CC_Owner_PRN = dbo.T_Users.U_PRN LEFT OUTER JOIN
                      dbo.V_Users ON dbo.T_Cell_Culture.CC_PI_PRN = dbo.V_Users.U_PRN

GO
