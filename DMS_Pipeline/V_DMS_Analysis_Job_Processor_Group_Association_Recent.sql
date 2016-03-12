/****** Object:  View [dbo].[V_DMS_Analysis_Job_Processor_Group_Association_Recent] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW V_DMS_Analysis_Job_Processor_Group_Association_Recent
AS
SELECT Group_Name,
       Job,
       [State],
       Dataset,
       Tool,
       [Parm File],
       [Settings File]
FROM S_DMS_V_Analysis_Job_Processor_Group_Association_Recent

GO
GRANT VIEW DEFINITION ON [dbo].[V_DMS_Analysis_Job_Processor_Group_Association_Recent] TO [PNL\D3M578] AS [dbo]
GO
