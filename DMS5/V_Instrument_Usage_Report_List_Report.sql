/****** Object:  View [dbo].[V_Instrument_Usage_Report_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Instrument_Usage_Report_List_Report]
AS
SELECT InstUsage.Seq,
       InstUsage.EMSL_Inst_ID AS [EMSL Inst ID],
       InstName.IN_Name AS [Instrument],
       InstUsage.[Type],
       InstUsage.Start,
       InstUsage.Minutes,
       InstUsage.Proposal,
       InstUsageType.[Name] AS [Usage],
       InstUsage.Users,
       InstUsage.Operator,
       InstUsage.[Comment],
       InstUsage.[Year],
       InstUsage.[Month],
       InstUsage.ID,
       dbo.CheckEMSLUsageItemValidity(Seq) AS Validation
FROM T_EMSL_Instrument_Usage_Report InstUsage
     INNER JOIN T_Instrument_Name InstName
       ON InstUsage.DMS_Inst_ID = InstName.Instrument_ID
     LEFT OUTER JOIN T_EMSL_Instrument_Usage_Type InstUsageType
       ON InstUsage.Usage_Type = InstUsageType.ID

GO
GRANT VIEW DEFINITION ON [dbo].[V_Instrument_Usage_Report_List_Report] TO [DDL_Viewer] AS [dbo]
GO
