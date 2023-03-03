/****** Object:  View [dbo].[V_Mage_Dataset_Factor_Metadata] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Mage_Dataset_Factor_Metadata] AS
SELECT DS.Dataset_ID AS ID,
       DS.Dataset_Num AS Dataset,
       Exp.Experiment_Num AS Experiment,
       C.Campaign_Num AS Campaign,
       DSN.DSS_name AS State,
       DSRating.DRN_name AS Rating,
       InstName.IN_name AS Instrument,
       DS.DS_comment AS Comment,
       DTN.DST_name AS Dataset_Type,
       LC.SC_Column_Number AS LC_Column,
       DS.DS_sec_sep AS Separation_Type,
       RRH.ID AS Request,
       ISNULL(DS.Acq_Time_Start, RRH.RDS_Run_Start) AS Acq_Start,
       ISNULL(DS.Acq_Time_End, RRH.RDS_Run_Finish) AS Acq_End,
       DS.Acq_Length_Minutes AS Acq_Length,
       DS.Scan_Count AS Scan_Count,
       DS.DS_created AS Created
FROM T_Dataset_State_Name AS DSN
     INNER JOIN T_Dataset AS DS
       ON DSN.Dataset_state_ID = DS.DS_state_ID
     INNER JOIN T_Dataset_Type_Name AS DTN
       ON DS.DS_type_ID = DTN.DST_Type_ID
     INNER JOIN T_Instrument_Name AS InstName
       ON DS.DS_instrument_name_ID = InstName.Instrument_ID
     INNER JOIN T_Dataset_Rating_Name AS DSRating
       ON DS.DS_rating = DSRating.DRN_state_ID
     INNER JOIN T_Experiments AS Exp
       ON DS.Exp_ID = Exp.Exp_ID
     INNER JOIN T_Campaign AS C
       ON Exp.EX_campaign_ID = C.Campaign_ID
     INNER JOIN T_LC_Column AS LC
       ON DS.DS_LC_column_ID = LC.ID
     INNER JOIN T_Requested_Run AS RRH
       ON DS.Dataset_ID = RRH.DatasetID
WHERE EXISTS ( SELECT FactorID,
                      TYPE,
                      TargetID,
                      Name,
                      VALUE
               FROM T_Factor
               WHERE (RRH.ID = TargetID) AND
                     (TYPE = 'Run_Request') )

GO
GRANT VIEW DEFINITION ON [dbo].[V_Mage_Dataset_Factor_Metadata] TO [DDL_Viewer] AS [dbo]
GO
