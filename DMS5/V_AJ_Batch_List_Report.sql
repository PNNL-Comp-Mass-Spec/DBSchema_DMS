/****** Object:  View [dbo].[V_AJ_Batch_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW dbo.V_AJ_Batch_List_Report
AS
SELECT     Batch_ID AS Batch, Batch_Description AS Description, Batch_Created AS Created
FROM         dbo.T_Analysis_Job_Batches


GO
GRANT VIEW DEFINITION ON [dbo].[V_AJ_Batch_List_Report] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_AJ_Batch_List_Report] TO [PNL\D3M580] AS [dbo]
GO
