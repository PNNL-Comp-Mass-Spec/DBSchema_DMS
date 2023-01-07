/****** Object:  View [dbo].[V_Pipeline_Local_Processors_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW V_Pipeline_Local_Processors_Detail_Report
AS
SELECT
    Processor_Name,
    State,
    Groups,
    GP_Groups,
    Machine,
    Latest_Request,
    id
FROM T_Local_Processors


GO
GRANT VIEW DEFINITION ON [dbo].[V_Pipeline_Local_Processors_Detail_Report] TO [DDL_Viewer] AS [dbo]
GO
