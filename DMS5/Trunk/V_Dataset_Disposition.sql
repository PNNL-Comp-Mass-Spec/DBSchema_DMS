/****** Object:  View [dbo].[V_Dataset_Disposition] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_Dataset_Disposition
AS
SELECT dbo.T_Dataset.Dataset_ID AS ID, '' AS [Sel.], 
    dbo.T_Dataset.Dataset_Num AS Dataset, 
    dbo.T_LC_Cart.Cart_Name AS [LC Cart], 
    dbo.T_Requested_Run_History.RDS_BatchID AS Batch, 
    dbo.T_Requested_Run_History.ID AS Request, 
    dbo.T_DatasetRatingName.DRN_name AS Rating, 
    dbo.T_Dataset.DS_comment AS Comment, 
    dbo.T_DatasetStateName.DSS_name AS State, 
    dbo.T_Instrument_Name.IN_name AS Instrument, 
    dbo.T_Dataset.DS_created AS Created, 
    dbo.T_Dataset.DS_Oper_PRN AS [Oper.]
FROM dbo.T_DatasetStateName INNER JOIN
    dbo.T_Dataset ON 
    dbo.T_DatasetStateName.Dataset_state_ID = dbo.T_Dataset.DS_state_ID
     INNER JOIN
    dbo.T_Instrument_Name ON 
    dbo.T_Dataset.DS_instrument_name_ID = dbo.T_Instrument_Name.Instrument_ID
     INNER JOIN
    dbo.T_DatasetRatingName ON 
    dbo.T_Dataset.DS_rating = dbo.T_DatasetRatingName.DRN_state_ID
     INNER JOIN
    dbo.T_Requested_Run_History ON 
    dbo.T_Dataset.Dataset_ID = dbo.T_Requested_Run_History.DatasetID
     INNER JOIN
    dbo.T_LC_Cart ON 
    dbo.T_Requested_Run_History.RDS_Cart_ID = dbo.T_LC_Cart.ID
WHERE (dbo.T_Dataset.DS_rating = - 10)

GO
