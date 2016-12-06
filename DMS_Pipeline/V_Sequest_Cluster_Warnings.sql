/****** Object:  View [dbo].[V_Sequest_Cluster_Warnings] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Sequest_Cluster_Warnings]
AS
SELECT 'SEQUEST node count is less than the expected value' AS Warning,
       JS.*
FROM dbo.V_Job_Steps AS JS
WHERE (Tool LIKE '%sequest%') AND
      (Evaluation_Code & 2 = 2)



GO
GRANT VIEW DEFINITION ON [dbo].[V_Sequest_Cluster_Warnings] TO [DDL_Viewer] AS [dbo]
GO
