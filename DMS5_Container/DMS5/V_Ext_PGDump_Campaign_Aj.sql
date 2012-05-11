/****** Object:  View [dbo].[V_Ext_PGDump_Campaign_Aj] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Ext_PGDump_Campaign_Aj
AS
SELECT	Campaign_ID AS id, 
		Campaign_Num AS campaign_name, 
		CM_created AS created, 
		CM_comment AS comment,
		AJ.AJ_JobID AS aj_id
FROM	T_Campaign C
		JOIN T_Experiments E ON E.EX_campaign_ID = C.Campaign_ID
		JOIN T_Dataset D ON D.Exp_ID = E.Exp_ID
		JOIN T_Analysis_Job AJ ON AJ.AJ_datasetID = D.Dataset_ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Ext_PGDump_Campaign_Aj] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Ext_PGDump_Campaign_Aj] TO [PNL\D3M580] AS [dbo]
GO
