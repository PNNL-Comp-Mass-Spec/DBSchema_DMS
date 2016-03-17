/****** Object:  View [dbo].[V_Instrument_Group_Allowed_Dataset_Type] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[V_Instrument_Group_Allowed_Dataset_Type]
AS
SELECT IADT.Dataset_Type AS [Dataset Type],
       SUM(CASE
               WHEN DS.Dataset_ID IS NULL THEN 0
               ELSE 1
           END) AS [Dataset Count],
       DTN.DST_Description AS [Type Description],
       IADT.[Comment] AS [Usage For This Group],
       IADT.IN_Group AS [Instrument Group]
FROM T_Instrument_Name InstName
     RIGHT OUTER JOIN T_Instrument_Group_Allowed_DS_Type IADT
                      INNER JOIN T_DatasetTypeName DTN
                        ON IADT.Dataset_Type = DTN.DST_name
       ON InstName.IN_Group = IADT.IN_Group
     LEFT OUTER JOIN T_Dataset DS
       ON InstName.Instrument_ID = DS.DS_instrument_name_ID AND
          DTN.DST_Type_ID = DS.DS_type_ID
GROUP BY IADT.Dataset_Type, DTN.DST_Description, IADT.[Comment], IADT.IN_Group


GO
GRANT VIEW DEFINITION ON [dbo].[V_Instrument_Group_Allowed_Dataset_Type] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Instrument_Group_Allowed_Dataset_Type] TO [PNL\D3M580] AS [dbo]
GO
