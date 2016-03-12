/****** Object:  View [dbo].[V_Ops_Logs_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[V_Ops_Logs_List_Report] AS 
SELECT  Entered ,
        EnteredBy ,
        Instrument ,
        'Operation' AS Type ,
        '' AS ID ,
        CONVERT(VARCHAR(12),ID) AS Log ,
	'' as Minutes ,
        Note ,
        0 AS [Request],
        '' AS [Usage] ,
        '' AS Proposal ,
        '' AS [EMSL_User],
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
		'' as Minutes ,
        Description AS Note ,
        0 AS [Request],
        '' AS [Usage] ,
        '' AS Proposal ,
        '' AS [EMSL_User],
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
		CONVERT(VARCHAR(12), Interval) as Minutes ,
        ISNULL(Comment, '') AS Note ,
        0 AS [Request],
        '' AS [Usage] ,
        '' AS Proposal ,
        '' AS [EMSL_User],
        DATEPART(YEAR, Start) AS Year ,
        DATEPART(MONTH, Start) AS Month ,
        DATEPART(DAY, Start) AS Day
FROM    T_Run_Interval
UNION
SELECT  DS.Acq_Time_Start AS Entered ,
        DS.DS_Oper_PRN AS EnteredBy ,
        T_Instrument_Name.IN_name AS Instrument ,
        'Dataset' AS Type ,
        '' AS ID ,
        '' AS Log ,
		CONVERT(VARCHAR(12),DS.Acq_Length_Minutes) as Minutes ,
        DS.Dataset_Num AS Note ,
        RR.ID AS [Request],
        EUT.Name AS [Usage] ,
        RR.RDS_EUS_Proposal_ID AS Proposal ,
        dbo.GetRequestedRunEUSUsersList(RR.ID, 'I') AS [EMSL_User],
        DATEPART(YEAR, DS.Acq_Time_Start) AS Year ,
        DATEPART(MONTH, DS.Acq_Time_Start) AS Month ,
        DATEPART(DAY, DS.Acq_Time_Start) AS Day
FROM    T_EUS_UsageType EUT
        INNER JOIN T_Requested_Run RR ON EUT.ID = RR.RDS_EUS_UsageType
        RIGHT OUTER JOIN T_Dataset DS
        INNER JOIN T_Instrument_Name ON DS.DS_instrument_name_ID = T_Instrument_Name.Instrument_ID ON RR.DatasetID = DS.Dataset_ID
WHERE   ( NOT ( DS.Acq_Time_Start IS NULL ))



GO
GRANT VIEW DEFINITION ON [dbo].[V_Ops_Logs_List_Report] TO [PNL\D3M578] AS [dbo]
GO
