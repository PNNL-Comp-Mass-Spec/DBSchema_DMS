/****** Object:  View [dbo].[V_Ext_PGDump_Campaign] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Ext_PGDump_Campaign
AS
SELECT     C.Campaign_ID AS id, C.Campaign_Num AS campaign_name, C.CM_created AS created, C.CM_comment AS comment, D.Dataset_ID AS ds_id
FROM         dbo.T_Campaign AS C INNER JOIN
                      dbo.T_Experiments AS E ON E.EX_campaign_ID = C.Campaign_ID INNER JOIN
                      dbo.T_Dataset AS D ON D.Exp_ID = E.Exp_ID

GO
GRANT VIEW DEFINITION ON [dbo].[V_Ext_PGDump_Campaign] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Ext_PGDump_Campaign] TO [PNL\D3M580] AS [dbo]
GO
