/****** Object:  View [dbo].[V_Tasks] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Tasks]
AS
SELECT J.job,
       J.priority,
       J.script,
       J.state,
       JSN.Name AS state_name,
       J.dataset,
       J.dataset_id,
       J.storage_server,
       J.instrument,
       J.instrument_class,
       J.max_simultaneous_captures,
       J.results_folder_name,
       J.imported,
       J.start,
       J.finish,
       J.archive_busy,
       J.transfer_folder_path,
       J.comment,
	   J.capture_subfolder
FROM T_Jobs J
     INNER JOIN T_Job_State_Name JSN
       ON J.State = JSN.ID


GO
