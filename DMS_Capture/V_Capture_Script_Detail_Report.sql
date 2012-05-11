/****** Object:  View [dbo].[V_Capture_Script_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Capture_Script_Detail_Report]
AS
SELECT     ID, Script, Description, Enabled, Results_Tag
FROM         dbo.T_Scripts

GO
