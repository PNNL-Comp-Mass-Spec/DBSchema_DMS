/****** Object:  View [dbo].[V_LC_Cart_Version_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create VIEW V_LC_Cart_Version_Entry
AS
SELECT     dbo.T_LC_Cart_Version.ID, dbo.T_LC_Cart.Cart_Name AS CartName, dbo.T_LC_Cart_Version.Version, 
                      dbo.T_LC_Cart_Version.Version_Number AS VersionNumber, dbo.T_LC_Cart_Version.Effective_Date AS EffectiveDate, 
                      dbo.T_LC_Cart_Version.Description
FROM         dbo.T_LC_Cart_Version INNER JOIN
                      dbo.T_LC_Cart ON dbo.T_LC_Cart_Version.Cart_ID = dbo.T_LC_Cart.ID

GO
