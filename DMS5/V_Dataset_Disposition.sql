/****** Object:  View [dbo].[V_Dataset_Disposition] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE view [dbo].[V_Dataset_Disposition] as
SELECT DS.Dataset_ID AS ID,
       '' AS [Sel.],
       DS.Dataset_Num AS Dataset,
       SPath.SP_URL + ISNULL(DS.DS_folder_name, DS.Dataset_Num) + '/QC/' + DS.Dataset_Num + '_BPI_MS.png' AS QC_Link,
       'http://prismweb.pnl.gov/smaqc/index.php/smaqc/instrument/' + InstName.In_Name AS SMAQC,
       LCC.Cart_Name AS [LC Cart],
       RRH.RDS_BatchID AS Batch,
       RRH.ID AS Request,
       DRN.DRN_name AS Rating,
       DS.DS_comment AS [Comment],
       DSN.DSS_name AS State,
       InstName.IN_name AS Instrument,
       DS.DS_created AS Created,
       DS.DS_Oper_PRN AS [Oper.]
FROM T_LC_Cart AS LCC
     INNER JOIN T_Requested_Run AS RRH
       ON LCC.ID = RRH.RDS_Cart_ID
     RIGHT OUTER JOIN T_DatasetStateName AS DSN
                      INNER JOIN T_Dataset AS DS
                        ON DSN.Dataset_state_ID = DS.DS_state_ID
                      INNER JOIN T_Instrument_Name AS InstName
                        ON DS.DS_instrument_name_ID = InstName.Instrument_ID
                      INNER JOIN T_DatasetRatingName AS DRN
                        ON DS.DS_rating = DRN.DRN_state_ID
       ON RRH.DatasetID = DS.Dataset_ID
     INNER JOIN t_storage_path AS SPath
       ON SPath.SP_path_ID = DS.DS_storage_path_ID
WHERE (DS.DS_rating = -10)



GO
GRANT VIEW DEFINITION ON [dbo].[V_Dataset_Disposition] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Dataset_Disposition] TO [PNL\D3M580] AS [dbo]
GO
