/****** Object:  View [dbo].[V_LC_Cart_Config_History_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_LC_Cart_Config_History_Entry
AS
SELECT        ID, Cart, Date_Of_Change AS DateOfChange, Description, Note, Entered, EnteredBy
FROM            dbo.T_LC_Cart_Config_History

GO
GRANT VIEW DEFINITION ON [dbo].[V_LC_Cart_Config_History_Entry] TO [DDL_Viewer] AS [dbo]
GO
