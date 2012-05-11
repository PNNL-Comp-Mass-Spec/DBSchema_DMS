/****** Object:  View [dbo].[V_Dataset_Metadata_KJA] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Dataset_Metadata_KJA
AS
SELECT     TD.Dataset_Num AS Name, TD.Dataset_ID AS ID, TE.Experiment_Num AS Experiment, TIN.IN_name AS Instrument, 
                      TD.DS_sec_sep AS [Separation Type], T_LC_Column.SC_Column_Number AS [LC Column], TD.DS_wellplate_num AS [Wellplate Number], 
                      TD.DS_well_num AS [Well Number], T_DatasetTypeName.DST_Name AS Type, T_Users.U_Name + ' (' + TD.DS_Oper_PRN + ')' AS Operator, 
                      TD.DS_comment AS Comment, TDRN.DRN_name AS Rating, T_Requested_Run.ID AS Request, TDSN.DSS_name AS State, 
                      TDASN.DASN_StateName AS [Archive State], TD.DS_created AS Created, TD.DS_folder_name AS [Folder Name], 
                      TD.DS_Comp_State AS [Compressed State], TD.DS_Compress_Date AS [Compressed Date], TD.Acq_Time_Start AS [Acquisition Start], 
                      TD.Acq_Time_End AS [Acquisition End], TD.Scan_Count AS [Scan Count], CONVERT(INT, TD.File_Size_Bytes / 1024.0 / 1024.0) AS [File Size MB], 
                      T_Campaign.Campaign_Num AS [Campaign Name], T_Campaign.CM_comment AS [Campaign Description]
FROM         T_Dataset AS TD INNER JOIN
                      T_DatasetStateName AS TDSN ON TD.DS_state_ID = TDSN.Dataset_state_ID INNER JOIN
                      T_Instrument_Name AS TIN ON TD.DS_instrument_name_ID = TIN.Instrument_ID INNER JOIN
                      T_DatasetTypeName ON TD.DS_type_ID = T_DatasetTypeName.DST_Type_ID INNER JOIN
                      T_Experiments AS TE ON TD.Exp_ID = TE.Exp_ID INNER JOIN
                      T_Users ON TD.DS_Oper_PRN = T_Users.U_PRN INNER JOIN
                      T_DatasetRatingName AS TDRN ON TD.DS_rating = TDRN.DRN_state_ID INNER JOIN
                      T_LC_Column ON TD.DS_LC_column_ID = T_LC_Column.ID INNER JOIN
                      T_Campaign ON TE.EX_campaign_ID = T_Campaign.Campaign_ID LEFT OUTER JOIN
                      T_Requested_Run ON TD.Dataset_ID = T_Requested_Run.DatasetID LEFT OUTER JOIN
                      T_Dataset_Archive AS TDA ON TDA.AS_Dataset_ID = TD.Dataset_ID LEFT OUTER JOIN
                      T_DatasetArchiveStateName AS TDASN ON TDASN.DASN_StateID = TDA.AS_state_ID
GO
GRANT VIEW DEFINITION ON [dbo].[V_Dataset_Metadata_KJA] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Dataset_Metadata_KJA] TO [PNL\D3M580] AS [dbo]
GO
