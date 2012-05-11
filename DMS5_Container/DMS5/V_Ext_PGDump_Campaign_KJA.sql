/****** Object:  View [dbo].[V_Ext_PGDump_Campaign_KJA] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Ext_PGDump_Campaign_KJA
AS
SELECT     Campaign_ID AS id, Campaign_Num AS campaign_name, CM_created AS created, CM_comment AS comment
FROM         dbo.T_Campaign


GO
GRANT VIEW DEFINITION ON [dbo].[V_Ext_PGDump_Campaign_KJA] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Ext_PGDump_Campaign_KJA] TO [PNL\D3M580] AS [dbo]
GO
