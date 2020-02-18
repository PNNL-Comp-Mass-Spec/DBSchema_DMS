/****** Object:  View [dbo].[V_MgrWorkDir] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_MgrWorkDir]
AS
-- This database does not keep track of the server name that a given manager is running on
-- Thus, this query includes the generic text ServerName for the WorkDir path, unless the WorkDir is itself a network share
SELECT Mgr_Name,
       CASE
           WHEN Value LIKE '\\%' THEN Value
           ELSE '\\ServerName\' + Replace(Value, ':\', '$\')
       END AS WorkDir_AdminShare
FROM V_Param_Value
WHERE (Param_Name = 'workdir')
GO
