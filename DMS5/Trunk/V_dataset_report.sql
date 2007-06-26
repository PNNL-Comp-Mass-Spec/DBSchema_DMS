/****** Object:  View [dbo].[V_dataset_report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_dataset_report
AS
SELECT     dbo.T_Dataset.Dataset_Num AS Dataset, dbo.T_Dataset.Dataset_ID AS ID, dbo.T_DatasetStateName.DSS_name AS State, 
                      dbo.T_DatasetRatingName.DRN_name AS Rating, dbo.T_Instrument_Name.IN_name AS Instrument, dbo.T_Dataset.DS_created AS Created, 
                      dbo.T_Dataset.DS_comment AS Comment, dbo.T_Dataset.Acq_Time_Start AS [Acq Start], CONVERT(int, CONVERT(real, 
                      dbo.T_Dataset.Acq_Time_End - dbo.T_Dataset.Acq_Time_Start) * 24 * 60) AS [Acq Length], dbo.T_Dataset.DS_Oper_PRN AS [Oper.], 
                      dbo.T_DatasetTypeName.DST_name AS Type, dbo.T_Experiments.Experiment_Num AS Experiment, 
                      dbo.V_Dataset_Folder_Paths.Dataset_Folder_Path AS [Dataset Folder Path], 
                      dbo.V_Dataset_Folder_Paths.Archive_Folder_Path AS [Archive Folder Path]
FROM         dbo.T_DatasetStateName INNER JOIN
                      dbo.T_Dataset ON dbo.T_DatasetStateName.Dataset_state_ID = dbo.T_Dataset.DS_state_ID INNER JOIN
                      dbo.T_DatasetTypeName ON dbo.T_Dataset.DS_type_ID = dbo.T_DatasetTypeName.DST_Type_ID INNER JOIN
                      dbo.T_Instrument_Name ON dbo.T_Dataset.DS_instrument_name_ID = dbo.T_Instrument_Name.Instrument_ID INNER JOIN
                      dbo.T_DatasetRatingName ON dbo.T_Dataset.DS_rating = dbo.T_DatasetRatingName.DRN_state_ID INNER JOIN
                      dbo.T_Experiments ON dbo.T_Dataset.Exp_ID = dbo.T_Experiments.Exp_ID INNER JOIN
                      dbo.V_Dataset_Folder_Paths ON dbo.T_Dataset.Dataset_ID = dbo.V_Dataset_Folder_Paths.Dataset_ID

GO
