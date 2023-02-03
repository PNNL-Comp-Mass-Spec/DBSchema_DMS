/****** Object:  View [dbo].[V_Assigned_Storage_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Assigned_Storage_Report]
AS
SELECT T_Instrument_Name.IN_name AS Instrument,
       Storage.SP_vol_name_client + Storage.SP_path AS Storage_Path,
       Src.SP_vol_name_server + Src.SP_path AS Source_Path,
       T_Instrument_Name.IN_capture_method AS Capture_Method
FROM T_Instrument_Name
     INNER JOIN ( SELECT SP_path_ID,
                         SP_path,
                         SP_vol_name_server
                  FROM t_storage_path
                  WHERE (SP_function = N'inbox') 
                ) AS Src
       ON T_Instrument_Name.IN_source_path_ID = Src.SP_path_ID
     INNER JOIN ( SELECT SP_path_ID,
                         SP_path,
                         SP_vol_name_client,
                         SP_vol_name_server
                  FROM t_storage_path
                  WHERE (SP_function = N'raw-storage') 
                ) AS Storage
       ON T_Instrument_Name.IN_storage_path_ID = Storage.SP_path_ID

GO
GRANT VIEW DEFINITION ON [dbo].[V_Assigned_Storage_Report] TO [DDL_Viewer] AS [dbo]
GO
