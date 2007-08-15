/****** Object:  View [dbo].[V_GetCandidateDatsetsForIDFUBroker] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/* get datasets that have entered the archive complete state (
 from the busy state) in the last N months*/
CREATE VIEW dbo.V_GetCandidateDatsetsForIDFUBroker
AS
SELECT     dbo.T_Dataset.Dataset_ID, dbo.T_Dataset.Dataset_Num AS DatasetName, dbo.T_Event_Log.Entered, 
                      dbo.T_Dataset.DS_instrument_name_ID AS InstrumentID
FROM         dbo.T_Dataset INNER JOIN
                      dbo.T_Dataset_Archive ON dbo.T_Dataset.Dataset_ID = dbo.T_Dataset_Archive.AS_Dataset_ID INNER JOIN
                      dbo.T_Event_Log ON dbo.T_Dataset.Dataset_ID = dbo.T_Event_Log.Target_ID
WHERE     (dbo.T_Event_Log.Target_Type = 6) AND (dbo.T_Event_Log.Target_State = 3) AND (dbo.T_Dataset_Archive.AS_state_ID = 3) AND 
                      (dbo.T_Event_Log.Prev_Target_State = 2) AND (DATEDIFF(MONTH, dbo.T_Event_Log.Entered, GETDATE()) < 4)

GO
