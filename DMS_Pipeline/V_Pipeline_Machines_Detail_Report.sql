/****** Object:  View [dbo].[V_Pipeline_Machines_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW V_Pipeline_Machines_Detail_Report
AS
SELECT 
    Machine AS [Machine], 
    Total_CPUs AS [Total CPUs], 
    CPUs_Available AS [CPUs Available]
FROM T_Machines

GO
GRANT VIEW DEFINITION ON [dbo].[V_Pipeline_Machines_Detail_Report] TO [DDL_Viewer] AS [dbo]
GO
