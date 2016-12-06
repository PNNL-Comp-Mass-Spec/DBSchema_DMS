/****** Object:  View [dbo].[V_KJA_Instrument_Stats_By_Year] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_KJA_Instrument_Stats_By_Year
AS
SELECT     dbo.T_Instrument_Name.IN_name AS inst_name, dbo.T_Instrument_Class.IN_class AS inst_class, COUNT(dbo.T_Instrument_Name.IN_class) 
                      AS dataset_count, SUM(datasets.File_Size_Bytes) AS total_data_volume_bytes, MIN(datasets.DS_created) AS creation_date
FROM         (SELECT     DS_created, DS_instrument_name_ID, File_Size_Bytes
                       FROM          dbo.T_Dataset
                       WHERE      (YEAR(DS_created) = 2005)) AS datasets INNER JOIN
                      dbo.T_Instrument_Name ON datasets.DS_instrument_name_ID = dbo.T_Instrument_Name.Instrument_ID INNER JOIN
                      dbo.T_Instrument_Class ON dbo.T_Instrument_Name.IN_class = dbo.T_Instrument_Class.IN_class
GROUP BY dbo.T_Instrument_Class.IN_class, dbo.T_Instrument_Name.IN_name

GO
GRANT VIEW DEFINITION ON [dbo].[V_KJA_Instrument_Stats_By_Year] TO [DDL_Viewer] AS [dbo]
GO
