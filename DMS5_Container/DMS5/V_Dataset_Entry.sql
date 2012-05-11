/****** Object:  View [dbo].[V_Dataset_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW V_Dataset_Entry
AS
SELECT     dbo.T_Experiments.Experiment_Num, dbo.T_Instrument_Name.IN_name AS DS_Instrument_Name, 
                      dbo.T_DatasetTypeName.DST_name AS DS_type_name, dbo.T_Dataset.Dataset_Num, dbo.T_Dataset.DS_folder_name, dbo.T_Dataset.DS_Oper_PRN, 
                      dbo.T_Dataset.DS_wellplate_num, dbo.T_Dataset.DS_well_num, dbo.T_Dataset.DS_sec_sep, dbo.T_Dataset.DS_comment, 
                      dbo.T_DatasetRatingName.DRN_name AS DS_Rating, 0 AS DS_Request, dbo.T_LC_Column.SC_Column_Number AS DS_Column, 
                      dbo.T_Internal_Standards.Name AS DS_internal_standard, 'no update' AS DS_EUSUsageType, 'no update' AS DS_EUSProposalID, 
                      'no update' AS DS_EUSUsers, 'no update' AS DS_LCCartName
FROM         dbo.T_Dataset INNER JOIN
                      dbo.T_Experiments ON dbo.T_Dataset.Exp_ID = dbo.T_Experiments.Exp_ID INNER JOIN
                      dbo.T_DatasetTypeName ON dbo.T_Dataset.DS_type_ID = dbo.T_DatasetTypeName.DST_Type_ID INNER JOIN
                      dbo.T_Instrument_Name ON dbo.T_Dataset.DS_instrument_name_ID = dbo.T_Instrument_Name.Instrument_ID INNER JOIN
                      dbo.T_DatasetRatingName ON dbo.T_Dataset.DS_rating = dbo.T_DatasetRatingName.DRN_state_ID INNER JOIN
                      dbo.T_LC_Column ON dbo.T_Dataset.DS_LC_column_ID = dbo.T_LC_Column.ID INNER JOIN
                      dbo.T_Internal_Standards ON dbo.T_Dataset.DS_internal_standard_ID = dbo.T_Internal_Standards.Internal_Std_Mix_ID

GO
GRANT VIEW DEFINITION ON [dbo].[V_Dataset_Entry] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Dataset_Entry] TO [PNL\D3M580] AS [dbo]
GO
