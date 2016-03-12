/****** Object:  View [dbo].[V_Pipeline_Local_Processors_Detail_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW V_Pipeline_Local_Processors_Detail_Report
AS
SELECT 
    Processor_Name AS [Processor Name], 
    State AS [State], 
    Groups AS [Groups], 
    GP_Groups AS [GP Groups], 
    Machine AS [Machine], 
    Latest_Request AS [Latest Request],
    ID AS [ID]
FROM T_Local_Processors

GO
GRANT VIEW DEFINITION ON [dbo].[V_Pipeline_Local_Processors_Detail_Report] TO [PNL\D3M578] AS [dbo]
GO
