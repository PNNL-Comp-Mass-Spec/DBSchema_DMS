/****** Object:  View [dbo].[V_Dataset_Instrument_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Dataset_Instrument_List_Report]
AS
SELECT InstName.IN_name AS instrument,
       DS.Dataset_Num AS dataset,
       DS.Dataset_ID AS id,
       DS.DS_created AS created,
       RR.ID AS request,
       RR.RDS_Requestor_PRN AS requester,
       E.Experiment_Num AS experiment,
       E.EX_researcher_PRN AS researcher,
       C.Campaign_Num AS campaign,
       InstName.instrument_id
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
GRANT VIEW DEFINITION ON [dbo].[V_Dataset_Instrument_List_Report] TO [DDL_Viewer] AS [dbo]
GO
