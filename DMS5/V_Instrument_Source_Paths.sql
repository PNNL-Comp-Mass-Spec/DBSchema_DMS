/****** Object:  View [dbo].[V_Instrument_Source_Paths] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Instrument_Source_Paths] AS 
SELECT SPath.SP_vol_name_server AS vol,
       SPath.SP_path AS [Path],
       InstName.IN_capture_method AS method,
       InstName.IN_name AS Instrument
FROM T_Instrument_Name AS InstName
     INNER JOIN t_storage_path AS SPath
       ON InstName.IN_source_path_ID = SPath.SP_path_ID
WHERE (InstName.IN_status = 'active') And InstName.Scan_SourceDir > 0


GO
GRANT VIEW DEFINITION ON [dbo].[V_Instrument_Source_Paths] TO [DDL_Viewer] AS [dbo]
GO
