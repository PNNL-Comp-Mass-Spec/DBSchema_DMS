/****** Object:  View [dbo].[V_Instrument_Utilization_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Instrument_Utilization_Report]
AS
SELECT InstName.IN_name AS Instrument,
       DS.DS_instrument_name_ID AS Instrument_ID,
       DS.Dataset_Num AS Dataset,
       DS.Dataset_ID,
       NULL AS Run_Start,
       DS.DS_created AS Run_Finish,
       RR.ID AS Request,
       RR.RDS_Requestor_PRN AS Requester
FROM dbo.T_Dataset DS
     INNER JOIN dbo.T_Instrument_Name InstName
       ON DS.DS_instrument_name_ID = InstName.Instrument_ID
     INNER JOIN dbo.T_Dataset_Type_Name DTN
       ON DS.DS_type_ID = DTN.DST_Type_ID
     LEFT OUTER JOIN dbo.T_Requested_Run RR
       ON DS.Dataset_ID = RR.DatasetID
WHERE DS.DS_state_ID = 3

GO
GRANT VIEW DEFINITION ON [dbo].[V_Instrument_Utilization_Report] TO [DDL_Viewer] AS [dbo]
GO
