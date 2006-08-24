/****** Object:  View [dbo].[V_Dataset_Load] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE VIEW dbo.V_Dataset_Load
AS
SELECT T_Dataset.Dataset_Num AS Dataset, 
   T_Experiments.Experiment_Num AS Experiment, 
   T_Instrument_Name.IN_name AS Instrument, 
   T_Dataset.DS_created AS Created, 
   T_DatasetStateName.DSS_name AS State, 
   T_DatasetTypeName.DST_name AS Type, 
   T_Dataset.DS_comment AS Comment, 
   T_Dataset.DS_Oper_PRN AS Operator, 
   T_Dataset.DS_well_num AS [Well Number], 
   T_Dataset.DS_sec_sep AS [Secondary Sep], 
   T_Dataset.DS_folder_name AS [Folder Name], 
   T_DatasetRatingName.DRN_name AS Rating
FROM T_Dataset INNER JOIN
   T_DatasetStateName ON 
   T_Dataset.DS_state_ID = T_DatasetStateName.Dataset_state_ID INNER
    JOIN
   T_Instrument_Name ON 
   T_Dataset.DS_instrument_name_ID = T_Instrument_Name.Instrument_ID
    INNER JOIN
   T_DatasetTypeName ON 
   T_Dataset.DS_type_ID = T_DatasetTypeName.DST_Type_ID INNER
    JOIN
   T_Experiments ON 
   T_Dataset.Exp_ID = T_Experiments.Exp_ID INNER JOIN
   T_DatasetRatingName ON 
   T_Dataset.DS_rating = T_DatasetRatingName.DRN_state_ID
GO
