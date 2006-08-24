/****** Object:  View [dbo].[V_Dataset_Export] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW V_Dataset_Export
AS
SELECT dbo.T_Dataset.Dataset_Num AS Dataset, 
    dbo.T_Experiments.Experiment_Num AS Experiment, 
    dbo.T_Experiments.EX_organism_name AS Organism, 
    dbo.T_Instrument_Name.IN_name AS Instrument, 
    dbo.T_Dataset.DS_sec_sep AS [Separation Type], 
    dbo.T_LC_Column.SC_Column_Number AS [LC Column], 
    dbo.T_Dataset.DS_wellplate_num AS [Wellplate Number], 
    dbo.T_Dataset.DS_well_num AS [Well Number], 
    Dataset_Int_Std.Name AS [Dataset Int Std], 
    dbo.T_DatasetTypeName.DST_name AS Type, 
    dbo.T_Users.U_Name + ' (' + dbo.T_Dataset.DS_Oper_PRN + ')' AS
     Operator, dbo.T_Dataset.DS_comment AS Comment, 
    dbo.T_DatasetRatingName.DRN_name AS Rating, 
    dbo.T_Requested_Run_History.ID AS Request, 
    dbo.T_DatasetStateName.DSS_name AS State, 
    dbo.T_Dataset.DS_created AS Created, 
    dbo.T_Dataset.DS_folder_name AS [Folder Name], 
    dbo.t_storage_path.SP_vol_name_client + dbo.t_storage_path.SP_path
     + dbo.T_Dataset.DS_folder_name AS [Dataset Folder Path], 
    dbo.t_storage_path.SP_path AS [Storage Folder], 
    dbo.t_storage_path.SP_vol_name_client + dbo.t_storage_path.SP_path
     AS Storage, 
    dbo.T_Dataset.DS_Comp_State AS [Compressed State], 
    dbo.T_Dataset.DS_Compress_Date AS [Compressed Date], 
    dbo.T_Dataset.Dataset_ID AS ID, 
    dbo.T_Dataset.Acq_Time_Start AS [Acquisition Start], 
    dbo.T_Dataset.Acq_Time_End AS [Acquisition End], 
    dbo.T_Dataset.Scan_Count AS [Scan Count], 
    PreDigest_Int_Std.Name AS [PreDigest Int Std], 
    PostDigest_Int_Std.Name AS [PostDigest Int Std]
FROM dbo.T_Dataset INNER JOIN
    dbo.T_DatasetStateName ON 
    dbo.T_Dataset.DS_state_ID = dbo.T_DatasetStateName.Dataset_state_ID
     INNER JOIN
    dbo.T_Instrument_Name ON 
    dbo.T_Dataset.DS_instrument_name_ID = dbo.T_Instrument_Name.Instrument_ID
     INNER JOIN
    dbo.T_DatasetTypeName ON 
    dbo.T_Dataset.DS_type_ID = dbo.T_DatasetTypeName.DST_Type_ID
     INNER JOIN
    dbo.T_Experiments ON 
    dbo.T_Dataset.Exp_ID = dbo.T_Experiments.Exp_ID INNER JOIN
    dbo.t_storage_path ON 
    dbo.T_Dataset.DS_storage_path_ID = dbo.t_storage_path.SP_path_ID
     INNER JOIN
    dbo.T_Users ON 
    dbo.T_Dataset.DS_Oper_PRN = dbo.T_Users.U_PRN INNER JOIN
    dbo.T_DatasetRatingName ON 
    dbo.T_Dataset.DS_rating = dbo.T_DatasetRatingName.DRN_state_ID
     INNER JOIN
    dbo.T_LC_Column ON 
    dbo.T_Dataset.DS_LC_column_ID = dbo.T_LC_Column.ID INNER
     JOIN
    dbo.T_Internal_Standards Dataset_Int_Std ON 
    dbo.T_Dataset.DS_internal_standard_ID = Dataset_Int_Std.Internal_Std_Mix_ID
     INNER JOIN
    dbo.T_Internal_Standards PreDigest_Int_Std ON 
    dbo.T_Experiments.EX_internal_standard_ID = PreDigest_Int_Std.Internal_Std_Mix_ID
     INNER JOIN
    dbo.T_Internal_Standards PostDigest_Int_Std ON 
    dbo.T_Experiments.EX_postdigest_internal_std_ID = PostDigest_Int_Std.Internal_Std_Mix_ID
     LEFT OUTER JOIN
    dbo.T_Requested_Run_History ON 
    dbo.T_Dataset.Dataset_ID = dbo.T_Requested_Run_History.DatasetID

GO
