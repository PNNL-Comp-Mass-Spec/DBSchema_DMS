/****** Object:  View [dbo].[V_Dataset_Metadata_KJA] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Dataset_Metadata_KJA
AS
SELECT     TD.Dataset_Num AS Name, TD.Dataset_ID AS ID, TE.Experiment_Num AS Experiment, TIN.IN_name AS Instrument, 
                      TD.DS_sec_sep AS [Separation Type], dbo.T_LC_Column.SC_Column_Number AS [LC Column], TD.DS_wellplate_num AS [Wellplate Number], 
                      TD.DS_well_num AS [Well Number], dbo.T_DatasetTypeName.DST_name AS Type, dbo.T_Users.U_Name + ' (' + TD.DS_Oper_PRN + ')' AS Operator, 
                      TD.DS_comment AS Comment, TDRN.DRN_name AS Rating, dbo.T_Requested_Run_History.ID AS Request, TDSN.DSS_name AS State, 
                      TDASN.DASN_StateName AS [Archive State], TD.DS_created AS Created, TD.DS_folder_name AS [Folder Name], 
                      TD.DS_Comp_State AS [Compressed State], TD.DS_Compress_Date AS [Compressed Date], TD.Acq_Time_Start AS [Acquisition Start], 
                      TD.Acq_Time_End AS [Acquisition End], TD.Scan_Count AS [Scan Count], CONVERT(int, TD.File_Size_Bytes / 1024.0 / 1024.0) AS [File Size MB], 
                      TE.EX_cell_culture_list AS [Cell Culture List], TC.Campaign_Num AS Campaign, TC.CM_comment AS [Campaign Description]
FROM         dbo.T_Dataset AS TD INNER JOIN
                      dbo.T_DatasetStateName AS TDSN ON TD.DS_state_ID = TDSN.Dataset_state_ID INNER JOIN
                      dbo.T_Instrument_Name AS TIN ON TD.DS_instrument_name_ID = TIN.Instrument_ID INNER JOIN
                      dbo.T_DatasetTypeName ON TD.DS_type_ID = dbo.T_DatasetTypeName.DST_Type_ID INNER JOIN
                      dbo.T_Experiments AS TE ON TD.Exp_ID = TE.Exp_ID INNER JOIN
                      dbo.T_Users ON TD.DS_Oper_PRN = dbo.T_Users.U_PRN INNER JOIN
                      dbo.T_DatasetRatingName AS TDRN ON TD.DS_rating = TDRN.DRN_state_ID INNER JOIN
                      dbo.T_LC_Column ON TD.DS_LC_column_ID = dbo.T_LC_Column.ID INNER JOIN
                      dbo.T_Campaign AS TC ON TE.EX_campaign_ID = TC.Campaign_ID LEFT OUTER JOIN
                      dbo.T_Requested_Run_History ON TD.Dataset_ID = dbo.T_Requested_Run_History.DatasetID LEFT OUTER JOIN
                      dbo.T_Dataset_Archive AS TDA ON TDA.AS_Dataset_ID = TD.Dataset_ID LEFT OUTER JOIN
                      dbo.T_DatasetArchiveStateName AS TDASN ON TDASN.DASN_StateID = TDA.AS_state_ID

GO
