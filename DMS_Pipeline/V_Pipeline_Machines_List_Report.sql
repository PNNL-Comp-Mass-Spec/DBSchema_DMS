/****** Object:  View [dbo].[V_Pipeline_Machines_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Pipeline_Machines_List_Report]
AS
SELECT 
    machine,
    total_cpus,
    cpus_available
FROM T_Machines


GO
GRANT VIEW DEFINITION ON [dbo].[V_Pipeline_Machines_List_Report] TO [DDL_Viewer] AS [dbo]
GO
