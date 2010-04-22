/****** Object:  View [dbo].[V_Ext_PGDump_Campaign_Ex] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Ext_PGDump_Campaign_Ex
AS
SELECT	Campaign_ID AS id, 
		Campaign_Num AS campaign_name, 
		CM_created AS created, 
		CM_comment AS comment,
		E.Exp_ID AS ex_id
FROM	T_Campaign C
		JOIN T_Experiments E ON E.EX_campaign_ID = C.Campaign_ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Ext_PGDump_Campaign_Ex] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Ext_PGDump_Campaign_Ex] TO [PNL\D3M580] AS [dbo]
GO
