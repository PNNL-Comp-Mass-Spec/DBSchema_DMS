/****** Object:  View [dbo].[V_Dataset_Stats_Recent_Crosstab] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[V_Dataset_Stats_Recent_Crosstab]
AS
SELECT PivotData.State,
       PivotData.StateName AS Dataset_State,
       IsNull([Finnigan_Ion_Trap], 0) AS [Finnigan_Ion_Trap],
       IsNull([LTQ_FT], 0) AS [LTQ_FT],
       IsNull([Thermo_Exactive], 0) AS [Thermo_Exactive],
       IsNull([BRUKERFTMS], 0) AS [BRUKERFTMS],
       IsNull([Triple_Quad], 0) AS [Triple_Quad],
       IsNull([Finnigan_FTICR], 0) AS [Finnigan_FTICR],
       IsNull([IMS_Agilent_TOF], 0) AS [IMS_Agilent_TOF]
FROM ( SELECT DSN.Dataset_state_ID AS State,
              DSN.DSS_name AS StateName,
              Instrument.IN_class AS Instrument_Class,
              COUNT(*) AS Dataset_Count
       FROM dbo.T_Dataset DS
            INNER JOIN dbo.T_DatasetStateName DSN
              ON DS.DS_state_ID = DSN.Dataset_state_ID
            INNER JOIN dbo.T_Instrument_Name Instrument
              ON DS.DS_instrument_name_ID = Instrument.Instrument_ID
       WHERE (DS.DS_Last_Affected >= DATEADD(DAY, - 14, GETDATE()))
       GROUP BY DSN.Dataset_state_ID, DSN.DSS_name, Instrument.IN_class ) AS SourceTable
     PIVOT ( SUM(Dataset_Count)
             FOR Instrument_Class
             IN ( [BRUKERFTMS], [Finnigan_Ion_Trap], [LTQ_FT], [Thermo_Exactive], [Triple_Quad], 
             [Finnigan_FTICR], [IMS_Agilent_TOF] ) ) AS PivotData


GO
GRANT VIEW DEFINITION ON [dbo].[V_Dataset_Stats_Recent_Crosstab] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Dataset_Stats_Recent_Crosstab] TO [PNL\D3M580] AS [dbo]
GO
