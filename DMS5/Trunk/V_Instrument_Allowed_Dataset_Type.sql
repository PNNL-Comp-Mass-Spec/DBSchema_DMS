/****** Object:  View [dbo].[V_Instrument_Allowed_Dataset_Type] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[V_Instrument_Allowed_Dataset_Type]
  AS
SELECT IAGDT.Dataset_Type AS [Dataset Type],
       SUM(CASE WHEN DS.Dataset_ID IS NULL THEN 0 ELSE 1 END) AS [Dataset Count],
       DTN.DST_Description AS [Type Description],
       IAGDT.Comment AS [Usage For This Instrument],
       T_Instrument_Name.IN_name AS Instrument
FROM T_Instrument_Group_Allowed_DS_Type IAGDT
     INNER JOIN T_DatasetTypeName DTN
       ON IAGDT.Dataset_Type = DTN.DST_Name
     INNER JOIN T_Instrument_Name
       ON IAGDT.IN_Group = T_Instrument_Name.IN_Group
     LEFT OUTER JOIN T_Dataset DS
       ON T_Instrument_Name.Instrument_ID = DS.DS_instrument_name_ID AND
          DTN.DST_Type_ID = DS.DS_type_ID
GROUP BY IAGDT.Dataset_Type, DTN.DST_Description, IAGDT.Comment, T_Instrument_Name.IN_name


GO
GRANT VIEW DEFINITION ON [dbo].[V_Instrument_Allowed_Dataset_Type] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Instrument_Allowed_Dataset_Type] TO [PNL\D3M580] AS [dbo]
GO
