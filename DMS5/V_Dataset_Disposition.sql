/****** Object:  View [dbo].[V_Dataset_Disposition] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Dataset_Disposition]
AS
SELECT DS.Dataset_ID AS id,
       '' AS sel,
       DS.Dataset_Num AS dataset,
       SPath.SP_URL_HTTPS + ISNULL(DS.ds_folder_name, DS.Dataset_Num) + '/QC/' + DS.Dataset_Num + '_BPI_MS.png' AS qc_link,
       'http://prismsupport.pnl.gov/smaqc/index.php/smaqc/instrument/' + InstName.In_Name AS smaqc,
       LCC.Cart_Name AS lc_cart,
       RRH.RDS_BatchID AS batch,
       RRH.ID AS request,
       DRN.DRN_name AS rating,
       DS.DS_comment AS comment,
       DSN.DSS_name AS state,
       InstName.IN_name AS instrument,
       DS.DS_created AS created,
       DS.DS_Oper_PRN AS operator
FROM T_LC_Cart AS LCC
     INNER JOIN T_Requested_Run AS RRH
       ON LCC.ID = RRH.RDS_Cart_ID
     RIGHT OUTER JOIN T_Dataset_State_Name AS DSN
                      INNER JOIN T_Dataset AS DS
                        ON DSN.Dataset_state_ID = DS.DS_state_ID
                      INNER JOIN T_Instrument_Name AS InstName
                        ON DS.DS_instrument_name_ID = InstName.Instrument_ID
                      INNER JOIN T_Dataset_Rating_Name AS DRN
                        ON DS.DS_rating = DRN.DRN_state_ID
       ON RRH.DatasetID = DS.Dataset_ID
     INNER JOIN t_storage_path AS SPath
       ON SPath.SP_path_ID = DS.DS_storage_path_ID
WHERE (DS.DS_rating = -10)

GO
GRANT VIEW DEFINITION ON [dbo].[V_Dataset_Disposition] TO [DDL_Viewer] AS [dbo]
GO
