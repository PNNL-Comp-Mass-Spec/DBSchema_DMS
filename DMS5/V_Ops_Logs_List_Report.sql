/****** Object:  View [dbo].[V_Ops_Logs_List_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Ops_Logs_List_Report]
AS
SELECT entered,
       EnteredBy As entered_by,
       instrument,
       'Operation' AS type,
       '' AS id,
       CONVERT(VARCHAR(12),ID) AS log,
       '' AS minutes,
       note,
       0 AS request,
       '' AS usage,
       '' AS proposal,
       '' AS emsl_user,
       DATEPART(YEAR, Entered) AS year,
       DATEPART(MONTH, Entered) AS month,
       DATEPART(DAY, Entered) AS day
FROM T_Instrument_Operation_History
UNION
SELECT Date_Of_Change AS Entered,
        EnteredBy AS Entered_By,
        Instrument,
        'Configuration' AS Type,
        '' AS ID,
        CONVERT(VARCHAR(12),ID) AS Log,
		'' AS Minutes,
        Description AS Note,
        0 AS Request,
        '' AS Usage,
        '' AS Proposal,
        '' AS EMSL_User,
        DATEPART(YEAR, Entered) AS Year,
        DATEPART(MONTH, Entered) AS Month,
        DATEPART(DAY, Entered) AS Day
FROM T_Instrument_Config_History
UNION
SELECT Start AS entered,
        '' AS entered_by,
        instrument,
        'Long Interval' AS type,
        CONVERT(VARCHAR(12), ID) AS id,
        '' AS log,
		CONVERT(VARCHAR(12), Interval) AS minutes,
        ISNULL(Comment, '') AS note,
        0 AS request,
        '' AS usage,
        '' AS proposal,
        '' AS emsl_user,
        DATEPART(YEAR, Start) AS year,
        DATEPART(MONTH, Start) AS month,
        DATEPART(DAY, Start) AS day
FROM T_Run_Interval
UNION
SELECT DS.Acq_Time_Start AS entered,
        DS.DS_Oper_PRN AS entered_by,
        T_Instrument_Name.IN_name AS instrument,
        'Dataset' AS type,
        '' AS id,
        '' AS log,
		CONVERT(VARCHAR(12),DS.Acq_Length_Minutes) AS minutes,
        DS.Dataset_Num AS note,
        RR.ID AS request,
        EUT.Name AS usage,
        RR.RDS_EUS_Proposal_ID AS proposal,
        dbo.get_requested_run_eus_users_list(RR.id, 'I') AS emsl_user,
        DATEPART(YEAR, DS.Acq_Time_Start) AS year,
        DATEPART(MONTH, DS.Acq_Time_Start) AS month,
        DATEPART(DAY, DS.Acq_Time_Start) AS day
FROM T_EUS_UsageType EUT
        INNER JOIN T_Requested_Run RR ON EUT.ID = RR.RDS_EUS_UsageType
        RIGHT OUTER JOIN T_Dataset DS
        INNER JOIN T_Instrument_Name ON DS.DS_instrument_name_ID = T_Instrument_Name.Instrument_ID ON RR.DatasetID = DS.Dataset_ID
WHERE   ( NOT ( DS.Acq_Time_Start IS NULL ))

GO
GRANT VIEW DEFINITION ON [dbo].[V_Ops_Logs_List_Report] TO [DDL_Viewer] AS [dbo]
GO
