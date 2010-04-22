/****** Object:  View [dbo].[V_Ext_Dataset_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Ext_Dataset_List_Report]
AS
SELECT DS.Dataset_ID AS ID,
       'x' as Sel,
       DS.Dataset_Num AS Dataset,
       Exp.Experiment_Num AS Experiment,
       C.Campaign_Num AS Campaign,
       DSN.DSS_name AS State,
       InstName.IN_name AS Instrument,
       DS.DS_created AS Created,
       DS.DS_comment AS COMMENT,
       DSRating.DRN_name AS Rating,
       DTN.DST_Name AS TYPE,
       DS.DS_Oper_PRN AS Operator,
       LC.SC_Column_Number AS [LC Column],
       DASN.DASN_StateName AS [Archive State]
FROM T_Dataset DS 
     JOIN T_Experiments Exp ON DS.Exp_ID = Exp.Exp_ID
     JOIN T_Campaign C ON Exp.EX_campaign_ID = C.Campaign_ID
     JOIN T_DatasetStateName DSN ON DSN.Dataset_state_ID = DS.DS_State_ID
     JOIN T_Instrument_Name InstName ON DS.DS_instrument_name_ID = InstName.Instrument_ID
     JOIN T_DatasetRatingName DSRating ON DS.DS_rating = DSRating.DRN_state_ID
     JOIN T_DatasetTypeName DTN ON DS.DS_type_ID = DTN.DST_Type_ID
     JOIN T_LC_Column LC ON DS.DS_LC_column_ID = LC.ID 
     JOIN T_DatasetArchiveStateName DASN ON DSN.Dataset_state_ID = DS.DS_state_ID AND DASN.DASN_StateName = 'Complete'
     JOIN T_Dataset_Archive DSA ON DASN.DASN_StateID = DSA.AS_state_ID AND DSA.AS_Dataset_ID = DS.Dataset_ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Ext_Dataset_List_Report] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Ext_Dataset_List_Report] TO [PNL\D3M580] AS [dbo]
GO
