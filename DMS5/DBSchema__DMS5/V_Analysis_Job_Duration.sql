/****** Object:  View [dbo].[V_Analysis_Job_Duration] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create view V_Analysis_Job_Duration 
as
SELECT     AJ_jobID AS Job, DATEDIFF(minute, AJ_start, AJ_finish) AS Duration
FROM         T_Analysis_Job
WHERE     (AJ_StateID = 4)

GO
