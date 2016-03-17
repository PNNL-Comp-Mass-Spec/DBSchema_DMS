/****** Object:  View [dbo].[V_Dataset_Instrument_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Dataset_Instrument_List_Report]
AS
SELECT InstName.IN_name AS Instrument,
       DS.Dataset_Num AS Dataset,
       DS.Dataset_ID AS ID,
       DS.DS_created AS Created,
       RR.ID AS Request,
       RR.RDS_Oper_PRN AS Requestor,
       E.Experiment_Num AS Experiment,
       E.EX_researcher_PRN AS Researcher,
       C.Campaign_Num AS Campaign,
       InstName.Instrument_ID
FROM T_Dataset DS
     INNER JOIN T_Experiments E
       ON DS.Exp_ID = E.Exp_ID
     INNER JOIN T_Instrument_Name InstName
       ON DS.DS_instrument_name_ID = InstName.Instrument_ID
     INNER JOIN T_Campaign C
       ON E.EX_campaign_ID = C.Campaign_ID
     LEFT OUTER JOIN T_Requested_Run RR
       ON DS.Dataset_ID = RR.DatasetID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Dataset_Instrument_List_Report] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Dataset_Instrument_List_Report] TO [PNL\D3M580] AS [dbo]
GO
