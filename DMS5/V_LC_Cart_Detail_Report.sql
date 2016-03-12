/****** Object:  View [dbo].[V_LC_Cart_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW V_LC_Cart_Detail_Report
AS
SELECT     
T.ID AS ID, 
T.Cart_Name AS [Cart Name], 
T.Cart_Description AS Descripton, S.Name AS State, 
dbo.GetLCConfigDocsPath(T.Cart_Name, '_config.xls') AS [Configuration]
FROM  T_LC_Cart T INNER JOIN
                      T_LC_Cart_State_Name S ON T.Cart_State_ID = S.ID

GO
GRANT VIEW DEFINITION ON [dbo].[V_LC_Cart_Detail_Report] TO [PNL\D3M578] AS [dbo]
GO
