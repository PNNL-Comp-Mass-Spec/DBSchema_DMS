/****** Object:  View [dbo].[V_GetCandidateDatsetsForIDFUBroker] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_GetCandidateDatsetsForIDFUBroker]
AS
-- Return the datasets that have been successfully archived within the lats 30 days (see Ticket #726))
SELECT DS.Dataset_ID,
       DS.Dataset_Num AS DatasetName,
       DA.AS_Last_Successful_Archive AS Entered,
       DS.DS_instrument_name_ID AS InstrumentID
FROM dbo.T_Dataset DS
     INNER JOIN dbo.T_Dataset_Archive DA
       ON DS.Dataset_ID = DA.AS_Dataset_ID
WHERE (DA.AS_state_ID IN (3, 4, 10)) AND
      (NOT (DA.AS_Last_Successful_Archive IS NULL)) AND
      (DATEDIFF(day, DA.AS_Last_Successful_Archive, GetDate()) < 30)


GO
GRANT VIEW DEFINITION ON [dbo].[V_GetCandidateDatsetsForIDFUBroker] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_GetCandidateDatsetsForIDFUBroker] TO [PNL\D3M580] AS [dbo]
GO
