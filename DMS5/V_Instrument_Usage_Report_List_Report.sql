/****** Object:  View [dbo].[V_Instrument_Usage_Report_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Instrument_Usage_Report_List_Report]
AS
SELECT InstUsage.seq,
       InstUsage.EMSL_Inst_ID AS emsl_inst_id,
       InstName.IN_Name AS instrument,
       InstUsage.type,
       InstUsage.start,
       InstUsage.minutes,
       InstUsage.proposal,
       InstUsageType.Name AS usage,
       InstUsage.users,
       InstUsage.operator,
       InstUsage.comment,
       InstUsage.year,
       InstUsage.month,
       InstUsage.dataset_id,
       dbo.CheckEMSLUsageItemValidity(Seq) AS validation
FROM T_EMSL_Instrument_Usage_Report InstUsage
     INNER JOIN T_Instrument_Name InstName
       ON InstUsage.DMS_Inst_ID = InstName.Instrument_ID
     LEFT OUTER JOIN T_EMSL_Instrument_Usage_Type InstUsageType
       ON InstUsage.Usage_Type = InstUsageType.ID


GO
GRANT VIEW DEFINITION ON [dbo].[V_Instrument_Usage_Report_List_Report] TO [DDL_Viewer] AS [dbo]
GO
