/****** Object:  View [dbo].[V_Find_Dataset] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW dbo.V_Find_Dataset
AS
SELECT  DS.Dataset_ID AS ID,
    DS.Dataset_Num AS Dataset,
    Exp.Experiment_Num AS Experiment,
    C.Campaign_Num AS Campaign,
    DSN.DSS_name AS State,
    InstName.IN_name AS Instrument,
    DS.DS_created AS Created,
    DS.DS_comment AS Comment,
    DSRating.DRN_name AS Rating,
    DTN.DST_Name AS Type,
    DS.DS_Oper_PRN AS Operator,
    DFP.Dataset_Folder_Path AS [Dataset Folder Path],
    DFP.Archive_Folder_Path AS [Archive Folder Path],
    DS.Acq_Time_Start AS [Acq Start],
    CONVERT(int, CONVERT(real, DS.Acq_Time_End - DS.Acq_Time_Start) * 24 * 60) AS [Acq Length],
    DS.Scan_Count AS [Scan Count],
    LC.SC_Column_Number,
    RRH.RDS_Blocking_Factor AS [Blocking Factor],
    RRH.RDS_Block AS Block,
    RRH.RDS_Run_Order AS [Run Order]
FROM T_DatasetStateName DSN
     INNER JOIN T_Dataset DS
       ON DSN.Dataset_state_ID = DS.DS_state_ID
     INNER JOIN T_DatasetTypeName DTN
       ON DS.DS_type_ID = DTN.DST_Type_ID
     INNER JOIN T_Instrument_Name InstName
       ON DS.DS_instrument_name_ID = InstName.Instrument_ID
     INNER JOIN T_DatasetRatingName DSRating
       ON DS.DS_rating = DSRating.DRN_state_ID
     INNER JOIN T_Experiments Exp
       ON DS.Exp_ID = Exp.Exp_ID
     INNER JOIN T_Campaign C
       ON Exp.EX_campaign_ID = C.Campaign_ID
     INNER JOIN V_Dataset_Folder_Paths DFP
       ON DS.Dataset_ID = DFP.Dataset_ID
     INNER JOIN T_LC_Column LC
       ON DS.DS_LC_column_ID = LC.ID
     LEFT OUTER JOIN T_Requested_Run_History RRH
       ON DS.Dataset_ID = RRH.DatasetID


GO
