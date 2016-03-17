/****** Object:  View [dbo].[V_LC_Cart_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW V_LC_Cart_List_Report
AS
SELECT     dbo.T_LC_Cart.ID, dbo.T_LC_Cart.Cart_Name AS [Cart Name], dbo.T_LC_Cart.Cart_Description AS Description, 
                      dbo.T_LC_Cart_State_Name.Name AS State, T.Versions
FROM         dbo.T_LC_Cart INNER JOIN
                      dbo.T_LC_Cart_State_Name ON dbo.T_LC_Cart.Cart_State_ID = dbo.T_LC_Cart_State_Name.ID LEFT OUTER JOIN
                          (SELECT     Cart_ID, COUNT(*) AS Versions
                            FROM          T_LC_Cart_Version
                            GROUP BY Cart_ID) T ON T.Cart_ID = dbo.T_LC_Cart.ID
WHERE     (dbo.T_LC_Cart.ID > 1)

GO
GRANT SELECT ON [dbo].[V_LC_Cart_List_Report] TO [DMS_LCMSNet_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_LC_Cart_List_Report] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_LC_Cart_List_Report] TO [PNL\D3M580] AS [dbo]
GO
