/****** Object:  View [dbo].[V_Dataset_Detail_Report_Ex] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Dataset_Detail_Report_Ex
AS
SELECT     TD.Dataset_Num AS Dataset, TE.Experiment_Num AS Experiment, dbo.T_Organisms.OG_name AS Organism, TIN.IN_name AS Instrument, 
                      TD.DS_sec_sep AS [Separation Type], dbo.T_LC_Cart.Cart_Name AS [LC Cart], dbo.T_LC_Column.SC_Column_Number AS [LC Column], 
                      TD.DS_wellplate_num AS [Wellplate Number], TD.DS_well_num AS [Well Number], TIS_1.Name AS [Predigest Int Std], 
                      TIS_2.Name AS [Postdigest Int Std], dbo.T_DatasetTypeName.DST_name AS Type, dbo.T_Users.U_Name + ' (' + TD.DS_Oper_PRN + ')' AS Operator, 
                      TD.DS_comment AS Comment, TDRN.DRN_name AS Rating, dbo.T_Requested_Run_History.ID AS Request, TD.DS_created AS Created, 
                      TD.DS_folder_name AS [Folder Name], TDSN.DSS_name AS State, dbo.V_Dataset_Folder_Paths.Dataset_Folder_Path AS [Dataset Folder Path], 
                      TDASN.DASN_StateName AS [Archive State], dbo.V_Dataset_Folder_Paths.Archive_Folder_Path AS [Archive Folder Path], 
                      TD.DS_Comp_State AS [Compressed State], TD.DS_Compress_Date AS [Compressed Date], A.Jobs, TD.Dataset_ID AS ID, 
                      TD.Acq_Time_Start AS [Acquisition Start], TD.Acq_Time_End AS [Acquisition End], dbo.T_Requested_Run_History.RDS_Run_Start AS [Run Start], 
                      dbo.T_Requested_Run_History.RDS_Run_Finish AS [Run Finish], TD.Scan_Count AS [Scan Count], CONVERT(int, TD.File_Size_Bytes / 1024.0 / 1024.0) 
                      AS [File Size (MB)], TD.File_Info_Last_Modified AS [File Info Updated]
FROM         dbo.T_LC_Cart INNER JOIN
                      dbo.T_Requested_Run_History ON dbo.T_LC_Cart.ID = dbo.T_Requested_Run_History.RDS_Cart_ID RIGHT OUTER JOIN
                      dbo.T_Dataset TD INNER JOIN
                      dbo.T_DatasetStateName TDSN ON TD.DS_state_ID = TDSN.Dataset_state_ID INNER JOIN
                      dbo.T_Instrument_Name TIN ON TD.DS_instrument_name_ID = TIN.Instrument_ID INNER JOIN
                      dbo.T_DatasetTypeName ON TD.DS_type_ID = dbo.T_DatasetTypeName.DST_Type_ID INNER JOIN
                      dbo.T_Experiments TE ON TD.Exp_ID = TE.Exp_ID INNER JOIN
                      dbo.V_Dataset_Folder_Paths ON dbo.V_Dataset_Folder_Paths.Dataset_ID = TD.Dataset_ID INNER JOIN
                      dbo.T_Users ON TD.DS_Oper_PRN = dbo.T_Users.U_PRN INNER JOIN
                      dbo.T_DatasetRatingName TDRN ON TD.DS_rating = TDRN.DRN_state_ID INNER JOIN
                      dbo.T_LC_Column ON TD.DS_LC_column_ID = dbo.T_LC_Column.ID INNER JOIN
                      dbo.T_Internal_Standards TIS_1 ON TE.EX_internal_standard_ID = TIS_1.Internal_Std_Mix_ID INNER JOIN
                      dbo.T_Internal_Standards TIS_2 ON TE.EX_postdigest_internal_std_ID = TIS_2.Internal_Std_Mix_ID INNER JOIN
                      dbo.T_Organisms ON TE.EX_organism_ID = dbo.T_Organisms.Organism_ID ON 
                      dbo.T_Requested_Run_History.DatasetID = TD.Dataset_ID LEFT OUTER JOIN
                          (SELECT     AJ_datasetID AS ID, COUNT(*) AS Jobs
                            FROM          T_Analysis_Job
                            GROUP BY AJ_datasetID) A ON A.ID = TD.Dataset_ID LEFT OUTER JOIN
                      dbo.T_Dataset_Archive TDA ON TDA.AS_Dataset_ID = TD.Dataset_ID LEFT OUTER JOIN
                      dbo.T_DatasetArchiveStateName TDASN ON TDASN.DASN_StateID = TDA.AS_state_ID

GO
