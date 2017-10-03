/****** Object:  View [dbo].[V_Processor_Tool_Group_Details] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Processor_Tool_Group_Details]
AS
SELECT PTG.Group_ID,
       PTG.Group_Name,
       PTG.Enabled AS Group_Enabled,
       PTG.Comment AS Group_Comment,
       PTGD.Mgr_ID,
       PTGD.Tool_Name,
       PTGD.Priority,
       PTGD.Enabled,
       PTGD.Comment,
       PTGD.Max_Job_Priority,
       PTGD.Last_Affected
FROM dbo.T_Processor_Tool_Group_Details AS PTGD
     INNER JOIN dbo.T_Processor_Tool_Groups AS PTG
       ON PTGD.Group_ID = PTG.Group_ID
WHERE PTG.Enabled > -10


GO
GRANT VIEW DEFINITION ON [dbo].[V_Processor_Tool_Group_Details] TO [DDL_Viewer] AS [dbo]
GO
