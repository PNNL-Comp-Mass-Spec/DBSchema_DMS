/****** Object:  View [dbo].[V_LC_Column_State_Picklist] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW dbo.V_LC_Column_State_Picklist
AS
SELECT     LCS_Name AS val, '' AS ex
FROM         dbo.T_LC_Column_State_Name



GO
GRANT VIEW DEFINITION ON [dbo].[V_LC_Column_State_Picklist] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_LC_Column_State_Picklist] TO [PNL\D3M580] AS [dbo]
GO
