/****** Object:  View [dbo].[V_Dataset_Disposition] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Dataset_Disposition
AS
SELECT DS.Dataset_ID AS ID,
       '' AS [Sel.],
       DS.Dataset_Num AS Dataset,
       LCC.Cart_Name AS [LC Cart],
       RRH.RDS_BatchID AS Batch,
       RRH.ID AS Request,
       DRN.DRN_name AS Rating,
       DS.DS_comment AS Comment,
       DSN.DSS_name AS State,
       InstName.IN_name AS Instrument,
       DS.DS_created AS Created,
       DS.DS_Oper_PRN AS [Oper.]
FROM dbo.T_LC_Cart LCC
     INNER JOIN dbo.T_Requested_Run_History RRH
       ON LCC.ID = RRH.RDS_Cart_ID
     RIGHT OUTER JOIN dbo.T_DatasetStateName DSN
                      INNER JOIN dbo.T_Dataset DS
                        ON DSN.Dataset_state_ID = DS.DS_state_ID
                      INNER JOIN dbo.T_Instrument_Name InstName
                        ON DS.DS_instrument_name_ID = InstName.Instrument_ID
                      INNER JOIN dbo.T_DatasetRatingName DRN
                        ON DS.DS_rating = DRN.DRN_state_ID
       ON RRH.DatasetID = DS.Dataset_ID
WHERE (DS.DS_rating = - 10)

GO
