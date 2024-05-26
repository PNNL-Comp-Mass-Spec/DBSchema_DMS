/****** Object:  View [dbo].[V_Query_Row_Counts] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Query_Row_Counts]
AS
SELECT 'DMS5' AS DB, 
        Query_ID, Object_Name, Where_Clause, Row_Count, 
        Last_Used, Last_Refresh, Usage, Refresh_Interval_Hours, Entered
FROM DMS5.dbo.T_Query_Row_Counts
UNION
SELECT 'DMS_Capture' AS DB, 
        Query_ID, Object_Name, Where_Clause, Row_Count, 
        Last_Used, Last_Refresh, Usage, Refresh_Interval_Hours, Entered
FROM DMS_Capture.dbo.T_Query_Row_Counts
UNION
SELECT 'DMS_Pipeline' AS DB, 
        Query_ID, Object_Name, Where_Clause, Row_Count, 
        Last_Used, Last_Refresh, Usage, Refresh_Interval_Hours, Entered
FROM DMS_Pipeline.dbo.T_Query_Row_Counts
UNION
SELECT 'DMS_Data_Package' AS DB, 
        Query_ID, Object_Name, Where_Clause, Row_Count, 
        Last_Used, Last_Refresh, Usage, Refresh_Interval_Hours, Entered
FROM DMS_Data_Package.dbo.T_Query_Row_Counts
UNION
SELECT 'Ontology_Lookup' AS DB, 
        Query_ID, Object_Name, Where_Clause, Row_Count, 
        Last_Used, Last_Refresh, Usage, Refresh_Interval_Hours, Entered
FROM Ontology_Lookup.dbo.T_Query_Row_Counts

GO
GRANT VIEW DEFINITION ON [dbo].[V_Query_Row_Counts] TO [DDL_Viewer] AS [dbo]
GO
