/****** Object:  View [dbo].[V_LC_Cart_Component_History] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_LC_Cart_Component_History
AS
SELECT     dbo.T_LC_Cart_Component_History.ID AS [Seq.], dbo.T_LC_Cart_Components.ID, dbo.T_LC_Cart.Cart_Name AS Cart, 
                      dbo.T_LC_Cart_Positions.Name AS [Cart Position], dbo.T_LC_Cart_Components.Serial_Number, dbo.T_LC_Cart_Component_History.Action, 
                      dbo.T_LC_Cart_Component_History.Starting_Date, dbo.T_LC_Cart_Component_History.Ending_Date, dbo.T_LC_Cart_Component_History.Comment, 
                      dbo.T_Users.U_Name AS [Staff Member], dbo.T_LC_Cart_Component_Type.Type, dbo.T_LC_Cart_Components.Manufacturer, 
                      dbo.T_LC_Cart_Components.Part_Number, dbo.T_LC_Cart_Components.Property_Number
FROM         dbo.T_LC_Cart_Components INNER JOIN
                      dbo.T_LC_Cart_Component_History ON dbo.T_LC_Cart_Components.ID = dbo.T_LC_Cart_Component_History.Cart_Component INNER JOIN
                      dbo.T_LC_Cart_Component_Type ON dbo.T_LC_Cart_Components.Type = dbo.T_LC_Cart_Component_Type.ID LEFT OUTER JOIN
                      dbo.T_LC_Cart INNER JOIN
                      dbo.T_LC_Cart_Component_Postition ON dbo.T_LC_Cart.ID = dbo.T_LC_Cart_Component_Postition.Cart_ID INNER JOIN
                      dbo.T_LC_Cart_Positions ON dbo.T_LC_Cart_Component_Postition.Position_ID = dbo.T_LC_Cart_Positions.ID ON 
                      dbo.T_LC_Cart_Component_History.Component_Position = dbo.T_LC_Cart_Component_Postition.ID INNER JOIN
                      dbo.T_Users ON dbo.T_LC_Cart_Component_History.Operator = dbo.T_Users.ID

GO
