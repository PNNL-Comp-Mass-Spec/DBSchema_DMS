/****** Object:  View [dbo].[V_Pipeline_Step_Tool_Storage_Paths] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Pipeline_Step_Tool_Storage_Paths]
AS
SELECT id AS step_tool_id,
       name AS step_tool,
       type,
       description,
       Coalesce(param_file_storage_path, '') AS param_file_storage_path
FROM T_Step_Tools


GO
