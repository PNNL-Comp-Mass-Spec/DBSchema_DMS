/****** Object:  View [dbo].[V_Instrument_Allowed_Dataset_Type] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Instrument_Allowed_Dataset_Type]
  AS
SELECT IADT.Dataset_Type AS [Dataset Type],
       SUM(CASE WHEN DS.Dataset_ID IS NULL THEN 0 ELSE 1 END) AS [Dataset Count],
       DTN.DST_Description AS [Type Description],
       IADT.COMMENT AS [Usage For This Instrument],
       IADT.Instrument
FROM T_Instrument_Allowed_Dataset_Type IADT
     INNER JOIN T_DatasetTypeName DTN
       ON IADT.Dataset_Type = DTN.DST_Name
     INNER JOIN T_Instrument_Name
       ON IADT.Instrument = T_Instrument_Name.IN_name
     LEFT OUTER JOIN T_Dataset DS
       ON T_Instrument_Name.Instrument_ID = DS.DS_instrument_name_ID AND
          DTN.DST_Type_ID = DS.DS_type_ID
GROUP BY IADT.Dataset_Type, DTN.DST_Description, IADT.COMMENT, IADT.Instrument

GO
GRANT VIEW DEFINITION ON [dbo].[V_Instrument_Allowed_Dataset_Type] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Instrument_Allowed_Dataset_Type] TO [PNL\D3M580] AS [dbo]
GO
