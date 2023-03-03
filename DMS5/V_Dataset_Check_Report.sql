/****** Object:  View [dbo].[V_Dataset_Check_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Dataset_Check_Report]
AS
SELECT DS.dataset_id,
       DS.Dataset_Num AS dataset,
       DS.DS_created AS created,
       DSN.DSS_name AS state,
       DS.DS_Last_Affected As last_affected,
       SPath.SP_machine_name AS storage,
       InstName.IN_name AS instrument
FROM dbo.T_Dataset DS
     INNER JOIN dbo.T_Dataset_State_Name DSN
       ON DS.DS_state_ID = DSN.Dataset_state_ID
     INNER JOIN dbo.t_storage_path SPath
       ON DS.DS_storage_path_ID = SPath.SP_path_ID
     INNER JOIN dbo.T_Instrument_Name InstName
       ON DS.DS_instrument_name_ID = InstName.Instrument_ID
WHERE DS.DS_created >= DateAdd(DAY, -120, GetDate())

GO
GRANT VIEW DEFINITION ON [dbo].[V_Dataset_Check_Report] TO [DDL_Viewer] AS [dbo]
GO
