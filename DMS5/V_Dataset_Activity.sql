/****** Object:  View [dbo].[V_Dataset_Activity] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Dataset_Activity]
AS
SELECT DS.Dataset_Num AS Dataset,
       DS.DS_created AS Dataset_Created,
       Instrument.IN_name AS Instrument,
       CONVERT(varchar(64), DSN.DSS_name) AS State,
       DS.DS_Last_Affected AS State_Date
FROM dbo.T_Dataset DS
     INNER JOIN dbo.T_Dataset_State_Name DSN
       ON DS.DS_state_ID = DSN.Dataset_state_ID
     INNER JOIN dbo.T_Instrument_Name Instrument
       ON DS.DS_instrument_name_ID = Instrument.Instrument_ID
WHERE (DS.DS_Last_Affected >= DATEADD(DAY, - 14, GETDATE())) AND
      (DS.DS_state_ID IN (2, 5, 7, 8, 12))
UNION
SELECT DS.Dataset_Num AS Dataset,
       DS.DS_created AS Dataset_Created,
       dbo.T_Instrument_Name.IN_name AS Instrument,
       CONVERT(varchar(64), DASN.archive_state + ' (archive)') AS State,
       DA.AS_state_Last_Affected AS State_Date
FROM dbo.T_Dataset_Archive DA
     INNER JOIN dbo.T_Dataset_Archive_State_Name DASN
       ON DA.AS_state_ID = DASN.archive_state_id
     INNER JOIN dbo.T_Dataset_Archive_Update_State_Name AUSN
       ON DA.AS_update_state_ID = AUSN.AUS_stateID
     INNER JOIN dbo.T_Dataset DS
       ON DA.AS_Dataset_ID = DS.Dataset_ID
     INNER JOIN dbo.T_Instrument_Name
       ON DS.DS_instrument_name_ID = dbo.T_Instrument_Name.Instrument_ID
WHERE (DA.AS_state_Last_Affected >= DATEADD(day, -14, GETDATE())) AND
      (DA.AS_state_ID IN (2, 6, 8, 13))
UNION
SELECT DS.Dataset_Num AS Dataset,
       DS.DS_created AS Dataset_Created,
       dbo.T_Instrument_Name.IN_name AS Instrument,
       CONVERT(varchar(64), AUSN.AUS_name + ' (archive update)') AS State,
       DA.AS_update_state_Last_Affected AS State_Date
FROM dbo.T_Dataset_Archive DA
     INNER JOIN dbo.T_Dataset_Archive_State_Name DASN
       ON DA.AS_state_ID = DASN.archive_state_id
     INNER JOIN dbo.T_Dataset_Archive_Update_State_Name AUSN
       ON DA.AS_update_state_ID = AUSN.AUS_stateID
     INNER JOIN dbo.T_Dataset DS
       ON DA.AS_Dataset_ID = DS.Dataset_ID
     INNER JOIN dbo.T_Instrument_Name
       ON DS.DS_instrument_name_ID = dbo.T_Instrument_Name.Instrument_ID
WHERE (DA.AS_update_state_Last_Affected >= DATEADD(day, -14, GETDATE())) AND
      (DA.AS_update_state_ID IN (3, 5))

GO
GRANT VIEW DEFINITION ON [dbo].[V_Dataset_Activity] TO [DDL_Viewer] AS [dbo]
GO
