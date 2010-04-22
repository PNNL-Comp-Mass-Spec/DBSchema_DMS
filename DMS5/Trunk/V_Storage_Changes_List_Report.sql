/****** Object:  View [dbo].[V_Storage_Changes_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Storage_Changes_List_Report]
AS
SELECT 'Storage path changed: ' AS Change,
       TSP.SP_path_ID AS ID,
       Notes = CASE
                   WHEN TSP.SP_function <> TSP_BU.SP_function THEN '(Function: "' + TSP.SP_function 
                                                                   + '"<- is, was->"' +
                                                                   TSP_BU.SP_function + '") '
                   ELSE ''
               END + CASE
                         WHEN TSP.SP_path <> TSP_BU.SP_path THEN '(Path: "' + TSP.SP_path + 
                                                                 '"<- is, was->"' + TSP_BU.SP_path 
                                                                 + '") '
                         ELSE ''
                     END + 
                 CASE
                     WHEN TSP.SP_vol_name_client <> TSP_BU.SP_vol_name_client THEN 
                       '(Client: "' + TSP.SP_vol_name_client + '"<- is, was->"' +
                       TSP_BU.SP_vol_name_client + '") '
                     ELSE ''
                 END + 
                 CASE
                     WHEN TSP.SP_vol_name_server <> TSP_BU.SP_vol_name_server THEN 
                       '(Server: "' + TSP.SP_vol_name_server + '"<- is, was->"' +
                       TSP_BU.SP_vol_name_server + '") '
                     ELSE ''
                 END + 
                 CASE
                     WHEN TSP.SP_instrument_name <> TSP_BU.SP_instrument_name THEN 
                       '(Instrument: "' 
                       + TSP.SP_instrument_name + '"<- is, was->"' + TSP_BU.SP_instrument_name 
                       + '") '
                     ELSE ''
                 END
FROM t_storage_path AS TSP
     INNER JOIN t_storage_path_bkup AS TSP_BU
       ON TSP.SP_path_ID = TSP_BU.SP_path_ID
WHERE ((TSP.SP_path <> TSP_BU.SP_path) OR
       (TSP.SP_vol_name_client <> TSP_BU.SP_vol_name_client) OR
       (TSP.SP_vol_name_server <> TSP_BU.SP_vol_name_server) OR
       (TSP.SP_function <> TSP_BU.SP_function) OR
       (TSP.SP_instrument_name <> TSP_BU.SP_instrument_name) OR
       (TSP.SP_description <> TSP_BU.SP_description))
UNION
SELECT 'Instrument storage changed: ' AS Change,
       TIN.Instrument_ID AS ID,
       TIN.IN_Name + ' ' + '(Source: ' + cast(TIN.IN_source_path_ID AS varchar(6)) + '<- is, was->' 
       + cast(TIN_BU.IN_source_path_ID AS varchar(6)) + ') ' + '(Storage: ' + 
         cast(TIN.IN_storage_path_ID AS varchar(6)) + '<- is, was->' + 
         cast(TIN_BU.IN_storage_path_ID AS varchar(6)) + ')' AS Notes
FROM T_Instrument_Name AS TIN
     INNER JOIN T_Instrument_Name_Bkup AS TIN_BU
       ON TIN.Instrument_ID = TIN_BU.Instrument_ID
WHERE (TIN.IN_source_path_ID <> TIN_BU.IN_source_path_ID) OR
      (TIN.IN_storage_path_ID <> TIN_BU.IN_storage_path_ID)
UNION
SELECT 'Storage path added: ' AS Change,
       SP_path_ID AS ID,
       '' AS Notes
FROM t_storage_path AS TSP
WHERE SP_path_ID NOT IN ( SELECT SP_path_ID
                          FROM t_storage_path_bkup )
UNION
SELECT 'Storage path deleted: ' AS Change,
       SP_path_ID AS ID,
       '' AS Notes
FROM t_storage_path_bkup AS TSP_BU
WHERE SP_path_ID NOT IN ( SELECT SP_path_ID
                          FROM t_storage_path )

GO
GRANT VIEW DEFINITION ON [dbo].[V_Storage_Changes_List_Report] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Storage_Changes_List_Report] TO [PNL\D3M580] AS [dbo]
GO
