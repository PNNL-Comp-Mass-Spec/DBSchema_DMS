/****** Object:  View [dbo].[V_Dataset_Metadata] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Dataset_Metadata]
AS
SELECT TD.Dataset_Num AS Name,
       TD.Dataset_ID AS ID,
       TE.Experiment_Num AS Experiment,
       TIN.IN_name AS Instrument,
       TIN.IN_class AS Instrument_Description,
       TD.DS_sec_sep AS Separation_Type,
       LC.SC_Column_Number AS LC_Column,
       TD.DS_wellplate_num AS Wellplate_Number,
       TD.DS_well_num AS Well_Number,
       DTN.DST_name AS TYPE,
       U.Name_with_PRN AS Operator,
       TD.DS_comment AS COMMENT,
       TDRN.DRN_name AS Rating,
       RR.ID AS Request,
       TDSN.DSS_name AS State,
       TDASN.archive_state AS Archive_State,
       TD.DS_created AS Created,
       TD.DS_folder_name AS Folder_Name,
       TD.DS_Comp_State AS Compressed_State,
       TD.DS_Compress_Date AS Compressed_Date,
       TD.Acq_Time_Start AS Acquisition_Start,
       TD.Acq_Time_End AS Acquisition_End,
       TD.Scan_Count AS Scan_Count,
       CONVERT(int, TD.File_Size_Bytes / 1024.0 / 1024.0) AS File_Size_MB
FROM T_Dataset AS TD
     INNER JOIN T_Dataset_State_Name AS TDSN
       ON TD.DS_state_ID = TDSN.Dataset_state_ID
     INNER JOIN T_Instrument_Name AS TIN
       ON TD.DS_instrument_name_ID = TIN.Instrument_ID
     INNER JOIN T_Dataset_Type_Name DTN
       ON TD.DS_type_ID = DTN.DST_Type_ID
     INNER JOIN T_Experiments AS TE
       ON TD.Exp_ID = TE.Exp_ID
     INNER JOIN T_Users U
       ON TD.DS_Oper_PRN = U.U_PRN
     INNER JOIN T_Dataset_Rating_Name AS TDRN
       ON TD.DS_rating = TDRN.DRN_state_ID
     INNER JOIN T_LC_Column LC
       ON TD.DS_LC_column_ID = LC.ID
     LEFT OUTER JOIN T_Requested_Run RR
       ON TD.Dataset_ID = RR.DatasetID
     LEFT OUTER JOIN T_Dataset_Archive AS TDA
       ON TDA.AS_Dataset_ID = TD.Dataset_ID
     LEFT OUTER JOIN T_Dataset_Archive_State_Name AS TDASN
       ON TDASN.archive_state_id = TDA.AS_state_ID

GO
GRANT VIEW DEFINITION ON [dbo].[V_Dataset_Metadata] TO [DDL_Viewer] AS [dbo]
GO
