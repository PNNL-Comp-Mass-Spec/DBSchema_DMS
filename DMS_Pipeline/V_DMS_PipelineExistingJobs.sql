/****** Object:  View [dbo].[V_DMS_PipelineExistingJobs] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW V_DMS_PipelineExistingJobs
AS
SELECT Job,
       State
FROM S_DMS_V_GetPipelineExistingJobs

GO
GRANT VIEW DEFINITION ON [dbo].[V_DMS_PipelineExistingJobs] TO [PNL\D3M578] AS [dbo]
GO
