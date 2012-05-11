/****** Object:  View [dbo].[V_Material_Log_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Material_Log_List_Report
AS
SELECT     dbo.T_Material_Log.ID, dbo.T_Material_Log.Date, dbo.T_Material_Log.Type, dbo.T_Material_Log.Item, dbo.T_Material_Log.Initial_State AS Initial, 
                      dbo.T_Material_Log.Final_State AS Final, dbo.T_Users.U_Name + ' (' + dbo.T_Material_Log.User_PRN + ')' AS [User], 
                      dbo.T_Material_Log.Comment
FROM         dbo.T_Material_Log LEFT OUTER JOIN
                      dbo.T_Users ON dbo.T_Material_Log.User_PRN = dbo.T_Users.U_PRN

GO
GRANT VIEW DEFINITION ON [dbo].[V_Material_Log_List_Report] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Material_Log_List_Report] TO [PNL\D3M580] AS [dbo]
GO
