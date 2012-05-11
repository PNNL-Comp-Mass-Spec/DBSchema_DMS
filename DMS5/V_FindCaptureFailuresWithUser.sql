/****** Object:  View [dbo].[V_FindCaptureFailuresWithUser] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_FindCaptureFailuresWithUser
AS
SELECT DS.Dataset_ID AS [Dataset ID],
       DS.Dataset_Num AS [Dataset Name],
       U.U_Name AS [Operator Name],
       InstName.IN_name AS [Inst Name],
       ILR.[Assigned Source] AS [Xfer Folder]
FROM dbo.T_Dataset DS
     INNER JOIN dbo.T_Users U
       ON DS.DS_Oper_PRN = U.U_PRN
     INNER JOIN dbo.T_Instrument_Name InstName
       ON DS.DS_instrument_name_ID = InstName.Instrument_ID
     INNER JOIN dbo.T_DatasetStateName DSN
       ON DS.DS_state_ID = DSN.Dataset_state_ID
     INNER JOIN dbo.V_Instrument_List_Report ILR
       ON DS.DS_instrument_name_ID = ILR.ID
WHERE (DS.DS_state_ID = 5)


GO
GRANT VIEW DEFINITION ON [dbo].[V_FindCaptureFailuresWithUser] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_FindCaptureFailuresWithUser] TO [PNL\D3M580] AS [dbo]
GO
