/****** Object:  View [dbo].[V_Mgr_Work_Dir] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Mgr_Work_Dir]
AS
-- This database does not keep track of the server name that a given manager is running on
-- Thus, this query includes the generic text ServerName for the WorkDir path, unless the WorkDir is itself a network share
SELECT mgr_name,
       CASE
           WHEN Value LIKE '\\%' THEN Value
           ELSE '\\ServerName\' + Replace(Value, ':\', '$\')
       END AS work_dir_admin_share
FROM V_Param_Value
WHERE (Param_Name = 'workdir')


GO
