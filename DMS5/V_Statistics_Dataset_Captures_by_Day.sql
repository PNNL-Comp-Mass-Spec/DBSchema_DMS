/****** Object:  View [dbo].[V_Statistics_Dataset_Captures_by_Day] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Statistics_Dataset_Captures_by_Day]
AS
SELECT YEAR(T_Dataset.DS_created) AS [Year],
       MONTH(T_Dataset.DS_created) AS [Month],
       DAY(T_Dataset.DS_created) AS [Day],
       CONVERT(date,  CONVERT(char(5), YEAR(T_Dataset.DS_created)) + '-' + CONVERT(char(2), MONTH(T_Dataset.DS_created)) + '-' + CONVERT(char(2), DAY(T_Dataset.DS_created))) as [Date],
       COUNT(*) AS Datasets_Created
FROM T_Dataset
     INNER JOIN T_Instrument_Name
       ON T_Dataset.DS_instrument_name_ID = T_Instrument_Name.Instrument_ID
WHERE (T_Instrument_Name.IN_name NOT LIKE 'External%') AND
      (T_Instrument_Name.IN_name NOT LIKE 'Broad%') AND
      (T_Instrument_Name.IN_name NOT LIKE 'FHCRC%')
GROUP BY YEAR(T_Dataset.DS_created), MONTH(T_Dataset.DS_created), DAY(T_Dataset.DS_created)


GO
GRANT VIEW DEFINITION ON [dbo].[V_Statistics_Dataset_Captures_by_Day] TO [PNL\D3M578] AS [dbo]
GO
