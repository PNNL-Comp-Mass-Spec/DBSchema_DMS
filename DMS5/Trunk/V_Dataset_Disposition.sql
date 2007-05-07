/****** Object:  View [dbo].[V_Dataset_Disposition] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE view V_Dataset_Disposition
as
SELECT 
  T_Dataset.Dataset_ID                AS ID,
  ''                                  AS [Sel.],
  T_Dataset.Dataset_Num               AS Dataset,
  T_LC_Cart.Cart_Name                 AS [LC Cart],
  T_Requested_Run_History.RDS_BatchID AS Batch,
  T_Requested_Run_History.ID          AS Request,
  T_DatasetRatingName.DRN_name        AS Rating,
  T_Dataset.DS_comment                AS COMMENT,
  T_DatasetStateName.DSS_name         AS State,
  T_Instrument_Name.IN_name           AS Instrument,
  T_Dataset.DS_created                AS Created,
  T_Dataset.DS_Oper_PRN               AS [Oper.]
FROM   
  T_DatasetStateName
  INNER JOIN T_Dataset
    ON T_DatasetStateName.Dataset_state_ID = T_Dataset.DS_state_ID
  INNER JOIN T_Instrument_Name
    ON T_Dataset.DS_instrument_name_ID = T_Instrument_Name.Instrument_ID
  INNER JOIN T_DatasetRatingName
    ON T_Dataset.DS_rating = T_DatasetRatingName.DRN_state_ID
  INNER JOIN T_Requested_Run_History
    ON T_Dataset.Dataset_ID = T_Requested_Run_History.DatasetID
  INNER JOIN T_LC_Cart
    ON T_Requested_Run_History.RDS_Cart_ID = T_LC_Cart.ID
WHERE  (DS_rating = - 10)

GO
