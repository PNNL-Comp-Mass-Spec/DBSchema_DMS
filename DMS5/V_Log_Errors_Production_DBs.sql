/****** Object:  View [dbo].[V_Log_Errors_Production_DBs] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Log_Errors_Production_DBs]
AS
SELECT 'DMS_Capture' AS DB, Entry_ID, posted_by, Entered, type, message, Entered_By
FROM DMS_Capture.dbo.V_Log_Errors
UNION
SELECT 'DMS5' AS DB, Entry_ID, posted_by, Entered, type, message, '' AS Entered_By
FROM V_Log_Errors
UNION
SELECT 'DMS_Pipeline' AS DB, Entry_ID, posted_by, Entered, type, message, Entered_By
FROM DMS_Pipeline.dbo.V_Log_Errors
UNION
SELECT 'DMS_Data_Package' AS DB, Entry_ID, posted_by, Entered, type, message, Entered_By
FROM DMS_Data_Package.dbo.V_Log_Errors


GO
GRANT VIEW DEFINITION ON [dbo].[V_Log_Errors_Production_DBs] TO [DDL_Viewer] AS [dbo]
GO
