/****** Object:  View [dbo].[V_GetCandidateDatsetsForIDFUBroker] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_GetCandidateDatsetsForIDFUBroker]
AS
SELECT DS.Dataset_ID,
       DS.Dataset_Num AS DatasetName,
       Max(EL.Entered) AS Entered,
       DS.DS_instrument_name_ID AS InstrumentID
FROM dbo.T_Dataset DS
     INNER JOIN dbo.T_Dataset_Archive DA
       ON DS.Dataset_ID = DA.AS_Dataset_ID
     INNER JOIN dbo.T_Event_Log EL
       ON DS.Dataset_ID = EL.Target_ID
WHERE (EL.Target_Type = 6) AND
      (EL.Target_State = 3) AND
      (EL.Prev_Target_State IN (2, 12)) AND
      (DA.AS_state_ID IN (3, 4, 10)) AND
      (DATEDIFF(MONTH, EL.Entered, GETDATE()) < 4)
GROUP BY DS.Dataset_ID, DS.Dataset_Num, DS.DS_instrument_name_ID

GO
