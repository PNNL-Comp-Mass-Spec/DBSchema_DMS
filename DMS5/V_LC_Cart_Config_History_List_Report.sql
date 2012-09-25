/****** Object:  View [dbo].[V_LC_Cart_Config_History_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 CREATE view V_LC_Cart_Config_History_List_Report as
SELECT        TIH.ID, TIH.Cart, TIH.Date_Of_Change AS [Date Of Change], TIH.Description, CASE WHEN DATALENGTH(TIH.Note) < 150 THEN Note ELSE SUBSTRING(TIH.Note, 1, 
                         150) + ' (more...)' END AS Note, TIH.Entered, TU.U_Name + ' (' + TIH.EnteredBy + ')' AS EnteredBy
FROM            T_LC_Cart_Config_History AS TIH LEFT OUTER JOIN
                         T_Users AS TU ON TIH.EnteredBy = TU.U_PRN
GO
GRANT VIEW DEFINITION ON [dbo].[V_LC_Cart_Config_History_List_Report] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_LC_Cart_Config_History_List_Report] TO [PNL\D3M580] AS [dbo]
GO
