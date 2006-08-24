/****** Object:  View [dbo].[V_Dataset_Detail_Report_Ex] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW V_Dataset_Detail_Report_Ex
AS
SELECT     
TD.Dataset_Num AS Dataset, 
TE.Experiment_Num AS Experiment, 
TE.EX_organism_name AS Organism, 
TIN.IN_name AS Instrument, 
TD.DS_sec_sep AS [Separation Type], 
T_LC_Column.SC_Column_Number AS [LC Column], 
TD.DS_wellplate_num AS [Wellplate Number], 
TD.DS_well_num AS [Well Number], 
TIS_1.Name AS [Predigest Int Std], 
TIS_2.Name AS [Postdigest Int Std], 
T_DatasetTypeName.DST_name AS Type, 
T_Users.U_Name + ' (' + TD.DS_Oper_PRN + ')' AS Operator, TD.DS_comment AS Comment, 
TDRN.DRN_name AS Rating, T_Requested_Run_History.ID AS Request, 
TDSN.DSS_name AS State, 
TDASN.DASN_StateName AS [Archive State],
TD.DS_created AS Created, TD.DS_folder_name AS [Folder Name], 
t_storage_path.SP_vol_name_client + t_storage_path.SP_path + TD.DS_folder_name AS [Dataset Folder Path], 
t_storage_path.SP_path AS [Storage Folder], t_storage_path.SP_vol_name_client + t_storage_path.SP_path AS Storage, 
TD.DS_Comp_State AS [Compressed State], TD.DS_Compress_Date AS [Compressed Date], A.Jobs, 
TD.Dataset_ID AS ID, TD.Acq_Time_Start AS [Acquisition Start], 
TD.Acq_Time_End AS [Acquisition End], 
TD.Scan_Count AS [Scan Count], 
CONVERT(int, TD.File_Size_Bytes / 1024.0 / 1024.0) AS [File Size (MB)], 
TD.File_Info_Last_Modified AS [File Info Updated]
FROM
T_Dataset TD INNER JOIN
T_DatasetStateName TDSN ON TD.DS_state_ID = TDSN.Dataset_state_ID INNER JOIN
T_Instrument_Name TIN ON TD.DS_instrument_name_ID = TIN.Instrument_ID INNER JOIN
T_DatasetTypeName ON TD.DS_type_ID = T_DatasetTypeName.DST_Type_ID INNER JOIN
T_Experiments TE ON TD.Exp_ID = TE.Exp_ID INNER JOIN
t_storage_path ON TD.DS_storage_path_ID = t_storage_path.SP_path_ID INNER JOIN
T_Users ON TD.DS_Oper_PRN = T_Users.U_PRN INNER JOIN
T_DatasetRatingName TDRN ON TD.DS_rating = TDRN.DRN_state_ID INNER JOIN
T_LC_Column ON TD.DS_LC_column_ID = T_LC_Column.ID INNER JOIN
T_Internal_Standards TIS_1 ON 
TE.EX_internal_standard_ID = TIS_1.Internal_Std_Mix_ID  INNER JOIN 
T_Internal_Standards TIS_2 ON 
TE.EX_postdigest_internal_std_ID = TIS_2.Internal_Std_Mix_ID LEFT OUTER JOIN
T_Requested_Run_History ON TD.Dataset_ID = T_Requested_Run_History.DatasetID LEFT OUTER JOIN
    (SELECT     AJ_datasetID AS ID, COUNT(*) AS Jobs
    FROM          T_Analysis_Job
    GROUP BY AJ_datasetID) A ON A.ID = TD.Dataset_ID
    LEFT OUTER JOIN
    T_Dataset_Archive TDA on TDA.AS_Dataset_ID = TD.Dataset_ID LEFT OUTER JOIN
T_DatasetArchiveStateName TDASN ON TDASN.DASN_stateID = TDA.AS_State_ID

GO
