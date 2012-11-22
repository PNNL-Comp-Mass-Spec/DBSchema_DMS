/****** Object:  View [dbo].[V_Pipeline_Script_MAC_With_Fields] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Pipeline_Script_MAC_With_Fields
AS
SELECT        Script AS Name, Description, Parameters, Fields
FROM            dbo.T_Scripts
WHERE        (Enabled = 'Y') AND (NOT (Fields IS NULL))

GO
