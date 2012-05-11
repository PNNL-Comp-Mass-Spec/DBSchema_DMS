/****** Object:  View [dbo].[V_Authority_Picker] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Authority_Picker
AS
SELECT     TOP 100 PERCENT Authority_ID AS ID, Name AS Display_Name, Description + ' <' + Web_Address + '>' AS Details
FROM         dbo.T_Naming_Authorities
ORDER BY Name

GO
GRANT SELECT ON [dbo].[V_Authority_Picker] TO [pnl\d3l243] AS [dbo]
GO
