/****** Object:  View [dbo].[V_Unanalyzed_Datasets_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW dbo.V_Unanalyzed_Datasets_Report
AS
SELECT V_Dataset_Analysis_Report.*
FROM V_Dataset_Analysis_Report
WHERE (Dataset NOT IN
       (SELECT DatasetNum
     FROM V_Analysis_Job
     WHERE (ToolName LIKE '%Sequest%') OR
        (ToolName LIKE '%ICR2LS%')))
GO
GRANT VIEW DEFINITION ON [dbo].[V_Unanalyzed_Datasets_Report] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Unanalyzed_Datasets_Report] TO [PNL\D3M580] AS [dbo]
GO
