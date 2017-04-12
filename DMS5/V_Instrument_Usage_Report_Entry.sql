/****** Object:  View [dbo].[V_Instrument_Usage_Report_Entry] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Instrument_Usage_Report_Entry] AS 
	SELECT InstUsage.EMSL_Inst_ID AS EMSLInstID,
	       InstName.IN_Name AS [Instrument],
	       InstUsage.[Type],
	       InstUsage.[Start],
	       InstUsage.[Minutes],
	       InstUsage.Proposal,
	       InstUsageType.[Name] AS [Usage],
	       InstUsage.Users,
	       InstUsage.Operator,
	       InstUsage.Comment,
	       InstUsage.[Year],
	       InstUsage.[Month],
	       InstUsage.ID,
	       InstUsage.Seq
	FROM T_EMSL_Instrument_Usage_Report InstUsage
	     INNER JOIN T_Instrument_Name InstName
	       ON InstUsage.DMS_Inst_ID = InstName.Instrument_ID
	     LEFT OUTER JOIN T_EMSL_Instrument_Usage_Type InstUsageType
	       ON InstUsage.Usage_Type = InstUsageType.ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Instrument_Usage_Report_Entry] TO [DDL_Viewer] AS [dbo]
GO
