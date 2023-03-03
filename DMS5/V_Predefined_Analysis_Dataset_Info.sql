/****** Object:  View [dbo].[V_Predefined_Analysis_Dataset_Info] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Predefined_Analysis_Dataset_Info]
AS
SELECT C.Campaign_Num AS Campaign,
       E.Experiment_Num AS Experiment,
       E.EX_comment AS Experiment_Comment,
       E.EX_Labelling AS Experiment_Labelling,
       Org.OG_name AS Organism,
       InstName.IN_name AS Instrument,
       InstName.IN_class AS InstrumentClass,
       DS.DS_comment AS Dataset_Comment,
       DS.Dataset_ID AS ID,
       DS.Dataset_Num AS Dataset,
       DS.DS_rating AS Rating,
       DRN.DRN_name AS Rating_Name,
       DSTypeName.DST_Name AS Dataset_Type,
       SepType.SS_name AS Separation_Type,
       ISNULL(DS.Acq_Time_Start, DS.DS_created) AS DS_Date,
       DS.Scan_Count
FROM dbo.T_Dataset DS
     INNER JOIN dbo.T_Instrument_Name InstName
       ON DS.DS_instrument_name_ID = InstName.Instrument_ID
     INNER JOIN dbo.T_Experiments E
       ON DS.Exp_ID = E.Exp_ID
     INNER JOIN dbo.T_Campaign C
       ON E.EX_campaign_ID = C.Campaign_ID
     INNER JOIN dbo.T_Dataset_Type_Name DSTypeName
       ON DS.DS_type_ID = DSTypeName.DST_Type_ID
     INNER JOIN dbo.T_Organisms Org
       ON E.EX_organism_ID = Org.Organism_ID
     INNER JOIN T_Dataset_Rating_Name DRN
       ON DS.DS_rating = DRN.DRN_state_ID
     LEFT OUTER JOIN dbo.T_Secondary_Sep SepType
       ON DS.DS_sec_sep = SepType.SS_name

GO
GRANT VIEW DEFINITION ON [dbo].[V_Predefined_Analysis_Dataset_Info] TO [DDL_Viewer] AS [dbo]
GO
