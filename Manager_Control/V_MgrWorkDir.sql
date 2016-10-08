/****** Object:  View [dbo].[V_MgrWorkDir] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_MgrWorkDir]
AS
-- This database does not keep track of the server name that a given manager is running on
-- Thus, this query includes the generic text ServerName for the WorkDir path, unless the WorkDir is itself a network share
SELECT M_Name,
       CASE
           WHEN VALUE LIKE '\\%' THEN VALUE
           ELSE '\\ServerName\' + Replace(VALUE, ':\', '$\')
       END AS WorkDir_AdminShare
FROM V_ParamValue
WHERE (ParamName = 'workdir')




GO
