/****** Object:  View [dbo].[V_Log_Errors_Production_DBs] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Log_Errors_Production_DBs]
AS
SELECT 'DMS_Capture' AS db, entry_id, posted_by, entered, type, message, entered_by
FROM DMS_Capture.dbo.V_Log_Errors
UNION
SELECT 'DMS5' AS db, entry_id, posted_by, entered, type, message, '' AS entered_by
FROM V_Log_Errors
UNION
SELECT 'DMS_Pipeline' AS db, entry_id, posted_by, entered, type, message, entered_by
FROM DMS_Pipeline.dbo.V_Log_Errors
UNION
SELECT 'DMS_Data_Package' AS db, entry_id, posted_by, entered, type, message, entered_by
FROM DMS_Data_Package.dbo.V_Log_Errors


GO
GRANT VIEW DEFINITION ON [dbo].[V_Log_Errors_Production_DBs] TO [DDL_Viewer] AS [dbo]
GO
