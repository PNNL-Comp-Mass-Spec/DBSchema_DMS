/****** Object:  View [dbo].[V_Ops_Logs_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- 
CREATE VIEW [dbo].[V_Ops_Logs_List_Report] AS 
SELECT  Entered ,
        EnteredBy ,
        Instrument ,
        'Operation' AS Type ,
        '' AS ID ,
        CONVERT(VARCHAR(12),ID) AS Log ,
        Note ,
        '' AS USAGE ,
        '' AS Proposal ,
        DATEPART(YEAR, Entered) AS Year ,
        DATEPART(MONTH, Entered) AS Month ,
        DATEPART(DAY, Entered) AS Day
FROM    T_Instrument_Operation_History
UNION
SELECT  Date_Of_Change AS Entered ,
        EnteredBy ,
        Instrument ,
        'Configuration' AS Type ,
        '' AS ID ,
        CONVERT(VARCHAR(12),ID) AS Log ,
       Description AS Note ,
        '' AS USAGE ,
        '' AS Proposal ,
        DATEPART(YEAR, Entered) AS Year ,
        DATEPART(MONTH, Entered) AS Month ,
        DATEPART(DAY, Entered) AS Day
FROM    T_Instrument_Config_History
UNION
SELECT  Start AS Entered ,
        '' AS EnteredBy ,
        Instrument ,
        'Long Interval' AS Type ,
        CONVERT(VARCHAR(12), ID) AS ID ,
        '' AS Log ,
        '[' + CONVERT(VARCHAR(12), Interval) + '] ' + ISNULL(Comment, '') AS Note ,
        '' AS USAGE ,
        '' AS Proposal ,
        DATEPART(YEAR, Start) AS Year ,
        DATEPART(MONTH, Start) AS Month ,
        DATEPART(DAY, Start) AS Day
FROM    T_Run_Interval
UNION
SELECT  T_Dataset.Acq_Time_Start AS Entered ,
        T_Dataset.DS_Oper_PRN AS EnteredBy ,
        T_Instrument_Name.IN_name AS Instrument ,
        'Dataset' AS Type ,
        '' AS ID ,
        '' AS Log ,
        T_Dataset.Dataset_Num AS Note ,
        T_EUS_UsageType.Name AS USAGE ,
        T_Requested_Run.RDS_EUS_Proposal_ID AS Proposal ,
        DATEPART(YEAR, T_Dataset.Acq_Time_Start) AS Year ,
        DATEPART(MONTH, T_Dataset.Acq_Time_Start) AS Month ,
        DATEPART(DAY, T_Dataset.Acq_Time_Start) AS Day
FROM    T_EUS_UsageType
        INNER JOIN T_Requested_Run ON T_EUS_UsageType.ID = T_Requested_Run.RDS_EUS_UsageType
        RIGHT OUTER JOIN T_Dataset
        INNER JOIN T_Instrument_Name ON T_Dataset.DS_instrument_name_ID = T_Instrument_Name.Instrument_ID ON T_Requested_Run.DatasetID = T_Dataset.Dataset_ID
WHERE   ( NOT ( T_Dataset.Acq_Time_Start IS NULL )
        )
GO
GRANT VIEW DEFINITION ON [dbo].[V_Ops_Logs_List_Report] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[V_Ops_Logs_List_Report] TO [PNL\D3M580] AS [dbo]
GO
