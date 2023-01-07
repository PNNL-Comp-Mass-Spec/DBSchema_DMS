/****** Object:  View [dbo].[V_LC_Cart_Config_History_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_LC_Cart_Config_History_Detail_Report
AS
SELECT id,
       cart,
       date_of_change,
       description,
       note,
       entered,
       enteredby AS entered_by
FROM dbo.T_LC_Cart_Config_History


GO
GRANT VIEW DEFINITION ON [dbo].[V_LC_Cart_Config_History_Detail_Report] TO [DDL_Viewer] AS [dbo]
GO
