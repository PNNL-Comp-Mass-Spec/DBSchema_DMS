/****** Object:  View [dbo].[V_AJ_Batch_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_AJ_Batch_List_Report
AS
SELECT Batch_ID AS batch, Batch_Description AS description, Batch_Created AS created
FROM dbo.T_Analysis_Job_Batches


GO
GRANT VIEW DEFINITION ON [dbo].[V_AJ_Batch_List_Report] TO [DDL_Viewer] AS [dbo]
GO
