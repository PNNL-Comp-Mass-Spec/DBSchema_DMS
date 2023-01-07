/****** Object:  View [dbo].[V_Instrument_Usage_Report_Export] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_Instrument_Usage_Report_Export]
AS
SELECT InstUsage.emsl_inst_id,
       InstName.IN_Name AS instrument,
       InstUsage.type,
       InstUsage.start,
       InstUsage.minutes,
       InstUsage.Proposal,
       InstUsageType.Name AS usage,
       InstUsage.users,
       InstUsage.Operator,
       IsNull(U.U_Name, EU.NAME_FM) AS operator_name,
       InstUsage.comment,
       InstUsage.year,
       InstUsage.month,
       InstUsage.dataset_id,
       InstUsage.seq,
       InstUsage.updated,
       InstUsage.updatedby
FROM T_EMSL_Instrument_Usage_Report InstUsage
     INNER JOIN T_Instrument_Name InstName
       ON InstUsage.DMS_Inst_ID = InstName.Instrument_ID
     LEFT OUTER JOIN T_EMSL_Instrument_Usage_Type InstUsageType
       ON InstUsage.Usage_Type = InstUsageType.ID
     LEFT OUTER JOIN T_EUS_Users EU
       ON InstUsage.Operator = EU.PERSON_ID
     LEFT OUTER JOIN T_Users U
       ON EU.HID = U.U_HID
WHERE InstUsage.Dataset_ID_Acq_Overlap Is Null


GO
