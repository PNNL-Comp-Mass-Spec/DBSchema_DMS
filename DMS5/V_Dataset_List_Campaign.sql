/****** Object:  View [dbo].[V_Dataset_List_Campaign] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE VIEW dbo.V_Dataset_List_Campaign
AS
SELECT T_Dataset.Dataset_Num AS Dataset, 
   T_DatasetStateName.DSS_name AS State, 
   T_DatasetRatingName.DRN_name AS Rating, 
   T_Instrument_Name.IN_class AS Class, 
   T_Campaign.Campaign_Num, 
   T_Dataset.Dataset_ID AS ID
FROM T_Dataset INNER JOIN
   T_DatasetStateName ON 
   T_Dataset.DS_state_ID = T_DatasetStateName.Dataset_state_ID INNER
    JOIN
   T_Experiments ON 
   T_Dataset.Exp_ID = T_Experiments.Exp_ID INNER JOIN
   T_DatasetRatingName ON 
   T_Dataset.DS_rating = T_DatasetRatingName.DRN_state_ID INNER
    JOIN
   T_Campaign ON 
   T_Experiments.EX_campaign_ID = T_Campaign.Campaign_ID INNER
    JOIN
   T_Instrument_Name ON 
   T_Dataset.DS_instrument_name_ID = T_Instrument_Name.Instrument_ID
GO
GRANT VIEW DEFINITION ON [dbo].[V_Dataset_List_Campaign] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Dataset_List_Campaign] TO [PNL\D3M580] AS [dbo]
GO
