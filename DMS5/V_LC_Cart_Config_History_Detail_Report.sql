/****** Object:  View [dbo].[V_LC_Cart_Config_History_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_LC_Cart_Config_History_Detail_Report
AS
SELECT        ID, Cart, Date_Of_Change AS [Date Of Change], Description, Note, Entered, EnteredBy
FROM            dbo.T_LC_Cart_Config_History

GO
GRANT VIEW DEFINITION ON [dbo].[V_LC_Cart_Config_History_Detail_Report] TO [PNL\D3M578] AS [dbo]
GO
