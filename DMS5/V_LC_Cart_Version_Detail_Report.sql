/****** Object:  View [dbo].[V_LC_Cart_Version_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW V_LC_Cart_Version_Detail_Report
AS
SELECT     
V.ID, 
T.Cart_Name AS [Cart Name], 
V.Version, 
V.Version_Number AS [Version Number], 
V.Effective_Date AS [Effective Date], 
V.Description,
dbo.GetLCConfigDocsPath(T.Cart_Name + '_' + cast(V.Version_Number as varchar(12)), '_valving.jpg') AS [Valving Diagram]
FROM         T_LC_Cart_Version V INNER JOIN
                      T_LC_Cart T ON V.Cart_ID = T.ID

GO
GRANT VIEW DEFINITION ON [dbo].[V_LC_Cart_Version_Detail_Report] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_LC_Cart_Version_Detail_Report] TO [PNL\D3M580] AS [dbo]
GO
