/****** Object:  View [dbo].[V_Dataset_QC_Ions_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Dataset_QC_Ions_List_Report]
AS
SELECT DQI.Dataset_ID AS dataset_id, 
       DS.Dataset_num AS dataset,
       DQI.Mz AS mz, 
       DQI.Max_Intensity AS max_intensity, 
       DQI.Median_Intensity AS median_intensity,
       E.Experiment_Num AS experiment,
       C.Campaign_Num AS campaign,
       InstName.IN_name AS instrument,
       DS.DS_created AS created,
       DS.DS_comment AS comment,
       DSN.DSS_name AS state,
       DS.acq_length_minutes AS acq_length,
       DTN.DST_name AS dataset_type
FROM T_Dataset_QC_Ions DQI
     INNER JOIN T_Dataset DS
       ON DQI.Dataset_ID = DS.Dataset_ID
     INNER JOIN T_Experiments E 
       ON DS.exp_id = E.exp_id
     INNER JOIN T_Campaign C 
       ON E.EX_campaign_ID = C.campaign_id
     INNER JOIN T_Instrument_Name instname 
       ON DS.DS_instrument_name_ID = instname.instrument_id
     INNER JOIN T_Dataset_State_Name DSN 
       ON DS.DS_state_ID = DSN.dataset_state_id
     INNER JOIN T_Dataset_Type_Name DTN 
       ON DS.DS_type_ID = dtn.DST_Type_ID

GO
GRANT VIEW DEFINITION ON [dbo].[V_Dataset_QC_Ions_List_Report] TO [DDL_Viewer] AS [dbo]
GO
