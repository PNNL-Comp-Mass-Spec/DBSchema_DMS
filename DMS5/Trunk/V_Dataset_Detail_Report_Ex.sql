/****** Object:  View [dbo].[V_Dataset_Detail_Report_Ex] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Dataset_Detail_Report_Ex
AS
SELECT DS.Dataset_Num AS Dataset,
       TE.Experiment_Num AS Experiment,
       OG.OG_name AS Organism,
       TIN.IN_name AS Instrument,
       DS.DS_sec_sep AS [Separation Type],
       LCCart.Cart_Name AS [LC Cart],
       LCCol.SC_Column_Number AS [LC Column],
       DS.DS_wellplate_num AS [Wellplate Number],
       DS.DS_well_num AS [Well Number],
       TIS_1.Name AS [Predigest Int Std],
       TIS_2.Name AS [Postdigest Int Std],
       DST.DST_Name AS Type,
       U.U_Name + ' (' + DS.DS_Oper_PRN + ')' AS Operator,
       DS.DS_comment AS Comment,
       TDRN.DRN_name AS Rating,
       RRH.ID AS Request,
       DS.DS_created AS Created,
       DS.DS_folder_name AS [Folder Name],
       TDSN.DSS_name AS State,
       ISNULL(SPath.SP_vol_name_client + SPath.SP_path + DS.Dataset_Num, '') AS [Dataset Folder Path],
       TDASN.DASN_StateName AS [Archive State],
       ISNULL(DAP.Archive_Path + '\' + DS.Dataset_Num, '') AS [Archive Folder Path],
       DS.DS_Comp_State AS [Compressed State],
       DS.DS_Compress_Date AS [Compressed Date],
       JobCountQ.Jobs,
       DS.Dataset_ID AS ID,
       DS.DS_PrepServerName AS [Prep Server],
       DS.Acq_Time_Start AS [Acquisition Start],
       DS.Acq_Time_End AS [Acquisition End],
       RRH.RDS_Run_Start AS [Run Start],
       RRH.RDS_Run_Finish AS [Run Finish],
       DS.Scan_Count AS [Scan Count],
	   DateDiff(minute, IsNull(DS.Acq_Time_Start, RRH.RDS_Run_Start), IsNull(DS.Acq_Time_End,RRH. RDS_Run_Finish)) AS [Acq Length],
       CONVERT(int, DS.File_Size_Bytes / 1024.0 / 1024.0) AS [File Size (MB)],
       DS.File_Info_Last_Modified AS [File Info Updated]
FROM dbo.t_storage_path SPath
     RIGHT OUTER JOIN dbo.T_Dataset DS
                      INNER JOIN dbo.T_DatasetStateName TDSN
                        ON DS.DS_state_ID = TDSN.Dataset_state_ID
                      INNER JOIN dbo.T_Instrument_Name TIN
                        ON DS.DS_instrument_name_ID = TIN.Instrument_ID
                      INNER JOIN dbo.T_DatasetTypeName DST
                        ON DS.DS_type_ID = DST.DST_Type_ID
                      INNER JOIN dbo.T_Experiments TE
                        ON DS.Exp_ID = TE.Exp_ID
                      INNER JOIN dbo.T_Users U
                        ON DS.DS_Oper_PRN = U.U_PRN
                      INNER JOIN dbo.T_DatasetRatingName TDRN
                        ON DS.DS_rating = TDRN.DRN_state_ID
                      INNER JOIN dbo.T_LC_Column LCCol
                        ON DS.DS_LC_column_ID = LCCol.ID
                      INNER JOIN dbo.T_Internal_Standards TIS_1
                        ON TE.EX_internal_standard_ID = TIS_1.Internal_Std_Mix_ID
                      INNER JOIN dbo.T_Internal_Standards TIS_2
                        ON TE.EX_postdigest_internal_std_ID = TIS_2.Internal_Std_Mix_ID
                      INNER JOIN dbo.T_Organisms OG
                        ON TE.EX_organism_ID = OG.Organism_ID
       ON SPath.SP_path_ID = DS.DS_storage_path_ID
     LEFT OUTER JOIN dbo.V_Dataset_Archive_Path DAP
       ON DS.Dataset_ID = DAP.Dataset_ID
     LEFT OUTER JOIN dbo.T_LC_Cart LCCart
                     INNER JOIN dbo.T_Requested_Run_History RRH
                       ON LCCart.ID = RRH.RDS_Cart_ID
       ON DS.Dataset_ID = RRH.DatasetID
     LEFT OUTER JOIN ( SELECT AJ_datasetID AS DatasetID, COUNT(*) AS Jobs
                       FROM T_Analysis_Job
                       GROUP BY AJ_datasetID ) JobCountQ
       ON JobCountQ.DatasetID = DS.Dataset_ID
     LEFT OUTER JOIN dbo.T_Dataset_Archive TDA
       ON TDA.AS_Dataset_ID = DS.Dataset_ID
     LEFT OUTER JOIN dbo.T_DatasetArchiveStateName TDASN
       ON TDASN.DASN_StateID = TDA.AS_state_ID
GO