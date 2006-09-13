/****** Object:  View [dbo].[V_Archive_Check_Update_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW dbo.V_Archive_Check_Update_Report
AS
SELECT distinct A.AS_Dataset_ID, D.Dataset_Num AS Dataset, I.IN_name AS Instrument, 
       S.SP_machine_name AS [Storage Server], D.DS_created AS Created, N.DASN_StateName AS State, 
       U.AUS_name AS [Update], A.AS_datetime AS Entered, A.AS_last_update AS [Last Update], 
       A.AS_last_verify AS [Last Verify], P.AP_archive_path AS [Archive Path], 
       P.AP_Server_Name AS [Archive Server]
FROM  T_Dataset_Archive A INNER JOIN
      T_Dataset D ON A.AS_Dataset_ID = D.Dataset_ID INNER JOIN
      T_DatasetArchiveStateName N ON A.AS_state_ID = N.DASN_StateID INNER JOIN
      T_Archive_Path P ON A.AS_storage_path_ID = P.AP_path_ID INNER JOIN
      T_Instrument_Name I ON D.DS_instrument_name_ID = I.Instrument_ID INNER JOIN
      T_Archive_Update_State_Name U ON A.AS_update_state_ID = U.AUS_stateID INNER JOIN
      t_storage_path S on S.SP_path_ID = A.AS_storage_path_ID
WHERE     (NOT (A.AS_update_state_ID IN (4, 6)))


GO
