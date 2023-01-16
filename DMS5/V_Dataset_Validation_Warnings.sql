/****** Object:  View [dbo].[V_Dataset_Validation_Warnings] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Dataset_Validation_Warnings]
AS
SELECT DS.Dataset_ID As Dataset_ID,
       DS.Dataset_Num AS Dataset,
       DS.DS_created AS Created,
       InstName.IN_name AS Instrument,
       RR.ID AS Requested_Run_ID,
       DS.DS_LC_column_ID AS LC_Column_ID,
       DS.DS_type_ID AS Dataset_Type_ID,
       DS.DS_sec_sep AS Separation_Type,
       CASE
           WHEN RR.ID IS NULL THEN 'Dataset does not have a requested run; create one'
           WHEN DS.DS_LC_column_ID IS NULL THEN 'LC Column ID is null'
           WHEN DS.DS_type_ID IS NULL THEN 'Dataset Type ID is null'
           WHEN DS.DS_sec_sep IS NULL THEN 'Separation_Type is null'
           ELSE 'Unknown Error'
       END AS Warning
FROM T_Dataset DS
        LEFT OUTER JOIN T_Instrument_Name InstName
        ON DS.DS_instrument_name_ID = InstName.Instrument_ID
        LEFT OUTER JOIN T_Requested_Run RR
        ON DS.Dataset_ID = RR.DatasetID
WHERE DS.DS_created >= '1/1/2015' AND
        (RR.ID IS NULL OR
        DS.DS_instrument_name_ID IS NULL OR
        DS.DS_LC_column_ID IS NULL OR
        DS.DS_type_ID IS NULL OR
        DS.DS_sec_sep IS NULL)


GO
GRANT VIEW DEFINITION ON [dbo].[V_Dataset_Validation_Warnings] TO [DDL_Viewer] AS [dbo]
GO
