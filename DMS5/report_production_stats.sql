/****** Object:  StoredProcedure [dbo].[report_production_stats] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[report_production_stats]
/****************************************************
**
**  Desc:
**      Generates dataset statistics for production instruments
**
**      Used by web page https://dms2.pnl.gov/production_instrument_stats/param
**      when it calls report_production_stats_proc
**
**  Auth:   grk
**  Date:   02/25/2005
**          03/01/2005 grk - added column for instrument name at end
**          12/19/2005 grk - added "MD" and "TS" prefixes (ticket #345)
**          08/17/2007 mem - Updated to examine Dataset State and Dataset Rating when counting Bad and Blank datasets (ticket #520)
**                         - Now excluding TS datasets from the Study Specific Datasets total (in addition to excluding Blank, QC, and Bad datasets)
**                         - Now extending the end date to 11:59:59 pm on the given day if @endDate does not contain a time component
**          04/25/2008 grk - Added "% Blank Datasets" column
**          08/30/2010 mem - Added parameter @productionOnly and updated to allow @startDate and/or @endDate to be blank
**                         - try/catch error handling
**          09/08/2010 mem - Now grouping Method Development (MD) datasets in with Troubleshooting datasets
**                         - Added checking for invalid dates
**          09/09/2010 mem - Now reporting % Study Specific datasets
**          09/26/2010 grk - Added accounting for reruns
**          02/03/2011 mem - Now using Dataset Acq Time (Acq_Time_Start) instead of Dataset Created (DS_Created), provided Acq_Time_Start is not null
**          03/30/2011 mem - Now reporting number of Unreviewed datasets
**                         - Removed the Troubleshooting column since datasets are no longer being updated that start with TS or MD
**          11/30/2011 mem - Added parameter @campaignIDFilterList
**                         - Added column "% EMSL Owned"
**                         - Added new columns, including "% EMSL Owned", "EMSL-Funded Study Specific Datasets", and "EF Study Specific Datasets per day"
**          03/15/2012 mem - Added parameter @eusUsageFilterList
**          02/23/2016 mem - Add set XACT_ABORT on
**          03/17/2017 mem - Pass this procedure's name to parse_delimited_list
**          04/05/2017 mem - Determine whether a dataset is EMSL funded using EUS usage type (previously used CM_Fraction_EMSL_Funded, which is estimated by the user for each campaign)
**                         - No longer differentiate reruns or unreviewed
**                         - Added parameter @instrumentFilterList
**                         - Changed [% EF Study Specific] to be based on [Total] instead of [EF_Total]
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**                         - Report AcqTimeDay, columns [Total AcqTimeDays], [Study Specific AcqTimeDays], [EF Total AcqTimeDays], [EF Study Specific AcqTimeDays], and [Hours AcqTime per Day]
**          04/13/2017 mem - If the work package for a dataset has Wiley Environmental, flag the dataset as EMSL funded
**                         - If the campaign for a dataset has Fraction_EMSL_Funded of 0.75 or more, flag the dataset as EMSL Funded
**          04/20/2018 mem - Allow Request_ID to be null
**          04/27/2018 mem - Add column [% EF Study Specific by AcqTime]
**          07/22/2019 mem - Refactor code into populate_campaign_filter_table, populate_instrument_filter_table, and resolve_start_and_end_dates
**          05/16/2022 mem - Treat 'Resource Owner' proposals as not EMSL funded
**          05/18/2022 mem - Treat additional proposal types as not EMSL funded
**          10/12/2022 mem - Add @showDebug
**                         - No longer use Fraction_EMSL_Funded from t_campaign to determine EMSL funding status
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          02/25/2023 bcg - Update output table column names to lower-case and no special characters
**          03/17/2023 mem - Add @includeProposalType
**          03/20/2023 mem - Treat proposal types 'Capacity' and 'Staff Time' as EMSL funded
**
*****************************************************/
(
    @startDate varchar(24),
    @endDate varchar(24),
    @productionOnly tinyint = 1,                -- When 0 then shows all instruments; otherwise limits the report to production instruments only
    @campaignIDFilterList varchar(2000) = '',   -- Comma separated list of campaign IDs
    @eusUsageFilterList varchar(2000) = '',     -- Comma separated list of EUS usage types, from table T_EUS_UsageType: CAP_DEV, MAINTENANCE, BROKEN, USER_ONSITE, USER_REMOTE, RESOURCE_OWNER
    @instrumentFilterList varchar(2000) = '',   -- Comma separated list of instrument names (% and * wild cards are allowed)
    @includeProposalType tinyint = 0,           -- When 1, summarize by proposal type
    @message varchar(256) = '' Output,
    @showDebug tinyint = 0                      -- When 1, summarize the contents of #Tmp_Datasets
)
AS
    Set XACT_ABORT, nocount on

    Declare @myRowCount int = 0
    Declare @myError int = 0
    Declare @result Int

    Declare @daysInRange float
    Declare @stDate datetime
    Declare @eDate datetime

    Declare @msg varchar(512)

    Declare @eDateAlternate datetime

    BEGIN TRY

    --------------------------------------------------------------------
    -- Validate the inputs
    --------------------------------------------------------------------
    --
    Set @productionOnly = IsNull(@productionOnly, 1)
    Set @campaignIDFilterList = LTrim(RTrim(IsNull(@campaignIDFilterList, '')))
    Set @eusUsageFilterList = LTrim(RTrim(IsNull(@eusUsageFilterList, '')))
    Set @instrumentFilterList = LTrim(RTrim(IsNull(@instrumentFilterList, '')))
    Set @includeProposalType = IsNull(@includeProposalType, 0)
    Set @showDebug = IsNull(@showDebug, 0)

    Set @message = ''

    --------------------------------------------------------------------
    -- Populate a temporary table with the Campaign IDs to filter on
    --------------------------------------------------------------------
    --
    CREATE TABLE #Tmp_CampaignFilter (
        Campaign_ID int NOT NULL,
        Fraction_EMSL_Funded float NULL
    )

    CREATE UNIQUE CLUSTERED INDEX #IX_Tmp_CampaignFilter ON #Tmp_CampaignFilter (Campaign_ID)

    Exec @result = populate_campaign_filter_table @campaignIDFilterList, @message=@message output

    If @result <> 0
    Begin
        print @message
        RAISERROR (@message, 11, 15)
    End

    --------------------------------------------------------------------
    -- Populate a temporary table with the Instrument IDs to filter on
    --------------------------------------------------------------------
    --
    CREATE TABLE #Tmp_InstrumentFilter (
        Instrument_ID int NOT NULL
    )

    CREATE UNIQUE CLUSTERED INDEX #IX_Tmp_InstrumentFilter ON #Tmp_InstrumentFilter (Instrument_ID)

    Exec @result = populate_instrument_filter_table @instrumentFilterList, @message=@message output

    If @result <> 0
    Begin
        print @message
        RAISERROR (@message, 11, 15)
    End

    --------------------------------------------------------------------
    -- Populate a temporary table with the EUS Usage types to filter on
    --------------------------------------------------------------------
    --
    CREATE TABLE #Tmp_EUSUsageFilter (
        Usage_ID int NOT NULL,
        Usage_Name varchar(64) NOT NULL
    )

    CREATE CLUSTERED INDEX #IX_Tmp_EUSUsageFilter ON #Tmp_EUSUsageFilter (Usage_ID)

    If @eusUsageFilterList <> ''
    Begin
        INSERT INTO #Tmp_EUSUsageFilter (Usage_Name, Usage_ID)
        SELECT DISTINCT Value AS Usage_Name, 0 AS ID
        FROM dbo.parse_delimited_list(@eusUsageFilterList, ',', 'report_production_stats')
        ORDER BY Value

        -- Look for invalid Usage_Name values
        Set @msg = ''
        SELECT @msg = Convert(varchar(12), UF.Usage_Name) + ',' + @msg
        FROM #Tmp_EUSUsageFilter UF
             LEFT OUTER JOIN T_EUS_UsageType U
               ON UF.Usage_Name = U.Name
        WHERE U.ID IS NULL
        --
        SELECT @myRowCount = @@RowCount

        If @myRowCount > 0
        Begin
            -- Remove the trailing comma
            Set @msg = Substring(@msg, 1, Len(@msg)-1)

            If @myRowCount = 1
                set @msg = 'Invalid Usage Type: ' + @msg
            Else
                set @msg = 'Invalid Usage Type: ' + @msg

            Set @msg = @msg + '; known types are: '

            SELECT @msg = @msg + Name + ', '
            FROM T_EUS_UsageType
            WHERE (ID <> 1)

            -- Remove the trailing comma
            Set @msg = Substring(@msg, 1, Len(@msg)-1)

            print @msg
            RAISERROR (@msg, 11, 15)
        End

        -- Update column Usage_ID
        --
        UPDATE #Tmp_EUSUsageFilter
        SET Usage_ID = U.ID
        FROM #Tmp_EUSUsageFilter UF
             INNER JOIN T_EUS_UsageType U
               ON UF.Usage_Name = U.Name

    End
    Else
    Begin
        INSERT INTO #Tmp_EUSUsageFilter (Usage_ID, Usage_Name)
        SELECT ID, Name
        FROM T_EUS_UsageType
        ORDER BY ID
    End

    --------------------------------------------------------------------
    -- Determine the start and end dates
    --------------------------------------------------------------------

    Exec @result = resolve_start_and_end_dates @startDate, @endDate, @stDate Output, @eDate Output, @message=@message output

    If @result <> 0
    Begin
        RAISERROR (@message, 11, 15)
    End

    --------------------------------------------------------------------
    -- Compute the number of days to be examined
    --------------------------------------------------------------------
    --
    set @daysInRange = DateDiff(dd, @stDate, @eDate)

    --------------------------------------------------------------------
    -- Populate a temporary table with the datasets to use
    --------------------------------------------------------------------
    --
    CREATE TABLE #Tmp_Datasets (
        Dataset_ID int NOT NULL,
        Campaign_ID int NOT NULL,
        Request_ID int NULL,            -- Every dataset should have a Request ID, but on rare occasions a dataset gets created without a RequestID; thus, allow this field to have null values
        EMSL_Funded tinyint NOT NULL,   -- 0 if not EMSL-funded, 1 if EMSL-funded
        Proposal_Type varchar(100)      -- Resource Owner, Intramural S&T, Capacity, Staff Time, Large-Scale EMSL Research, FICUS Research, etc.
    )

    CREATE CLUSTERED INDEX #IX_Tmp_Datasets ON #Tmp_Datasets (Dataset_ID, Campaign_ID)

    CREATE INDEX #IX_Tmp_Datasets_RequestID ON #Tmp_Datasets (Request_ID)

    If @eusUsageFilterList <> ''
    Begin
        -- Filter on the EMSL usage types defined in #Tmp_EUSUsageFilter
        --
        INSERT INTO #Tmp_Datasets( Dataset_ID,
                                   Campaign_ID,
                                   Request_ID,
                                   EMSL_Funded,
                                   Proposal_Type )
        SELECT D.Dataset_ID,
               E.EX_campaign_ID,
               RR.ID,
               CASE
                   WHEN IsNull(EUP.Proposal_Type, 'PROPRIETARY')
                        IN ('Partner', 'Proprietary', 'Proprietary Public', 'Proprietary_Public', 'Resource Owner') THEN 0  -- Not EMSL Funded
                   ELSE 1             -- EMSL Funded:
                                      -- 'Exploratory Research', 'FICUS JGI-EMSL', 'FICUS Research', 'Intramural S&T',
                                      -- 'Large-Scale EMSL Research', 'Limited Scope', 'Science Area Research',
                                      -- 'Capacity', 'Staff Time'
               END AS EMSL_Funded,
               EUP.Proposal_Type
        FROM T_Dataset D
             INNER JOIN T_Experiments E
               ON E.Exp_ID = D.Exp_ID
             INNER JOIN #Tmp_InstrumentFilter InstFilter
               ON D.DS_Instrument_Name_ID = InstFilter.Instrument_ID
             INNER JOIN T_Requested_Run RR
               ON D.Dataset_ID = RR.DatasetID
             INNER JOIN T_EUS_Proposals EUP
               ON RR.RDS_EUS_Proposal_ID = EUP.Proposal_ID
        WHERE ISNULL(D.Acq_Time_Start, D.DS_created) BETWEEN @stDate AND @eDate AND
              RR.RDS_EUS_UsageType IN ( SELECT Usage_ID
                                        FROM #Tmp_EUSUsageFilter )
        --
        SELECT @myRowCount = @@RowCount

    End
    Else
    Begin
        -- Note that this query uses a left outer join against T_Requested_Run
        -- because datasets acquired before 2006 were not required to have a requested run
        --
        INSERT INTO #Tmp_Datasets( Dataset_ID,
                                   Campaign_ID,
                                   Request_ID,
                                   EMSL_Funded,
                                   Proposal_Type )
        SELECT D.Dataset_ID,
               E.EX_campaign_ID,
               RR.ID,
               CASE
                   WHEN IsNull(EUP.Proposal_Type, 'PROPRIETARY')
                        IN ('Partner', 'Proprietary', 'Proprietary Public', 'Proprietary_Public', 'Resource Owner') THEN 0  -- Not EMSL Funded
                   ELSE 1             -- EMSL Funded:
                                      -- 'Exploratory Research', 'FICUS JGI-EMSL', 'FICUS Research', 'Intramural S&T',
                                      -- 'Large-Scale EMSL Research', 'Limited Scope', 'Science Area Research',
                                      -- 'Capacity', 'Staff Time'
               END AS EMSL_Funded,
               EUP.Proposal_Type
        FROM T_Dataset D
             INNER JOIN T_Experiments E
               ON E.Exp_ID = D.Exp_ID
             INNER JOIN #Tmp_InstrumentFilter InstFilter
               ON D.DS_Instrument_Name_ID = InstFilter.Instrument_ID
             LEFT OUTER JOIN T_Requested_Run RR
               ON D.Dataset_ID = RR.DatasetID
             LEFT OUTER JOIN T_EUS_Proposals EUP
               ON RR.RDS_EUS_Proposal_ID = EUP.Proposal_ID
        WHERE ISNULL(D.Acq_Time_Start, D.DS_created) BETWEEN @stDate AND @eDate
        --
        SELECT @myRowCount = @@RowCount

    End

    If @showDebug > 0
    Begin
        Select 'Initial Contents' As Status, EMSL_Funded, Count(*) As Datasets, Min(Dataset_ID) As Dataset_ID_First, Max(Dataset_ID) As Dataset_ID_Last
        From #Tmp_Datasets
        Group By EMSL_Funded
    End

    ---------------------------------------------------
    -- Examine the work package associated with datasets in #Tmp_Datasets
    -- to find additional datasets that are EMSL-Funded
    ---------------------------------------------------

    UPDATE #Tmp_Datasets
    SET EMSL_Funded = 1
    FROM #Tmp_Datasets DS
         INNER JOIN T_Requested_Run RR
           ON DS.Request_ID = RR.ID
         INNER JOIN T_Charge_Code CC
           ON RR.RDS_WorkPackage = CC.Charge_Code
    WHERE DS.EMSL_Funded = 0 And CC.SubAccount_Title LIKE '%Wiley Environmental%'
    --
    SELECT @myRowCount = @@RowCount

    If @showDebug > 0 And @myRowCount > 0
    Begin
        Select 'After updating EMSL_Funded for work packages with SubAccount containing "Wiley Environmental"' As Status, EMSL_Funded, Count(*) As Datasets, Min(Dataset_ID) As Dataset_ID_First, Max(Dataset_ID) As Dataset_ID_Last
        From #Tmp_Datasets
        Group By EMSL_Funded
    End

    ---------------------------------------------------
    -- Generate report
    ---------------------------------------------------

    If @includeProposalType > 0
    Begin

        SELECT
            Instrument AS instrument,
            Proposal_Type AS proposal_type,
            [Total] AS total_datasets,
            @daysInRange AS days_in_range,
            Convert(decimal(5,1), [Total]/@daysInRange) AS datasets_per_day,
            [Blank] AS blank_datasets,
            [QC] AS qc_datasets,
            -- [TS] as troubleshooting,
            [Bad] as bad_datasets,
            [Study Specific] AS study_specific_datasets,
            Convert(decimal(5,1), [Study Specific] / @daysInRange) AS study_specific_datasets_per_day,
            [EF Study Specific] AS emsl_funded_study_specific_datasets,
            Convert(decimal(5,1), [EF Study Specific] / @daysInRange) AS ef_study_specific_datasets_per_day,

            Convert(decimal(5,1), [Total_AcqTimeDays]) AS total_acq_time_days,
            Convert(decimal(5,1), [Study_Specific_AcqTimeDays]) AS study_specific_acq_time_days,
            Convert(decimal(5,1), [EF_Total_AcqTimeDays]) AS ef_total_acq_time_days,
            Convert(decimal(5,1), [EF_Study_Specific_AcqTimeDays]) AS ef_study_specific_acq_time_days,
            Convert(decimal(5,1), [Hours_AcqTime_per_Day]) as hours_acq_time_per_day,

            Instrument AS inst_,                        -- The website will show this column as "Inst."
            Percent_EMSL_Owned AS pct_inst_emsl_owned,

            -- EMSL Funded Counts:
            Convert(float, Convert(decimal(9,2), [EF_Total])) AS ef_total_datasets,
            Convert(decimal(5,1), [EF_Total]/@daysInRange) AS ef_datasets_per_day,
            -- Convert(float, Convert(decimal(9,2), [EF_Blank])) AS ef_blank_datasets,
            -- Convert(float, Convert(decimal(9,2), [EF_QC])) AS ef_qc_datasets,
            -- Convert(float, Convert(decimal(9,2), [EF_Bad])) as ef_bad_datasets,

            Convert(decimal(5,1), ([Blank] * 100.0 / [Total])) AS pct_blank_datasets,
            Convert(decimal(5,1), ([QC] * 100.0 / [Total])) AS pct_qc_datasets,
            Convert(decimal(5,1), ([Bad] * 100.0 / [Total])) AS pct_bad_datasets,
            -- Convert(decimal(5,1), ([Reruns] * 100.0 / [Total])) AS pct_reruns,
            Convert(decimal(5,1), ([Study Specific] * 100.0 / [Total])) AS pct_study_specific_datasets,
            CASE WHEN [Total] > 0 THEN Convert(decimal(5,1), [EF Study Specific] * 100.0 / [Total]) ELSE NULL END AS pct_ef_study_specific_datasets,
            CASE WHEN [Total_AcqTimeDays] > 0 THEN Convert(decimal(5,1), [EF_Total_AcqTimeDays] * 100.0 / [Total_AcqTimeDays]) ELSE NULL END AS pct_ef_study_specific_by_acq_time,

            Instrument AS inst
        FROM (
            SELECT Instrument, Percent_EMSL_Owned, Proposal_Type,
                [Total], [Bad], [Blank], [QC],
                [Total] - ([Blank] + [QC] + [Bad]) AS [Study Specific],
                [Total_AcqTimeDays],
                [Total_AcqTimeDays] - [BadBlankQC_AcqTimeDays] AS [Study_Specific_AcqTimeDays],

                Case When @daysInRange > 0.5 Then [Total_AcqTimeDays] / @daysInRange * 24 Else Null End AS [Hours_AcqTime_per_Day],

                [EF_Total], [EF_Bad], [EF_Blank], [EF_QC],
                [EF_Total] - ([EF_Blank] + [EF_QC] + [EF_Bad]) AS [EF Study Specific],
                [EF_Total_AcqTimeDays],
                [EF_Total_AcqTimeDays] - [EF_BadBlankQC_AcqTimeDays] AS [EF_Study_Specific_AcqTimeDays]

            FROM
                (SELECT Instrument,
                        Percent_EMSL_Owned,
                        Proposal_Type,
                        SUM([Total]) AS [Total],        -- Total (Good + bad)
                        SUM([Bad]) AS [Bad],            -- Bad (not blank)
                        SUM([Blank]) AS [Blank],        -- Blank (Good + bad)
                        SUM([QC]) AS [QC],              -- QC (not bad)

                        Sum([Total_AcqTimeDays]) AS [Total_AcqTimeDays],            -- Total time acquiring data
                        Sum([BadBlankQC_AcqTimeDays]) AS [BadBlankQC_AcqTimeDays],  -- Total time acquiring bad/blank/QC data

                        -- EMSL Funded (EF) Counts:
                        Sum([EF_Total]) AS [EF_Total],        -- EF Total (Good + bad)
                        Sum([EF_Bad]) AS [EF_Bad],            -- EF Bad (not blank)
                        Sum([EF_Blank]) AS [EF_Blank],        -- EF Blank (Good + bad)
                        Sum([EF_QC]) AS [EF_QC],              -- EF QC (not bad)

                        Sum([EF_Total_AcqTimeDays]) AS [EF_Total_AcqTimeDays],                 -- EF Total time acquiring data
                        Sum([EF_BadBlankQC_AcqTimeDays]) AS [EF_BadBlankQC_AcqTimeDays]        -- EF Total time acquiring bad/blank/QC data

                FROM
                    (    -- Select Good datasets (excluded Bad, Not Released, Unreviewed, etc.)
                        SELECT
                            I.IN_Name as Instrument,
                            I.Percent_EMSL_Owned,
                            DF.Proposal_Type,
                            COUNT(*) AS [Total],                                                        -- Total
                            0                                                            AS [Bad],      -- Bad
                            SUM(CASE WHEN D.Dataset_Num LIKE 'Blank%' THEN 1 ELSE 0 END) AS [Blank],    -- Blank
                            SUM(CASE WHEN D.Dataset_Num LIKE 'QC%' THEN 1 ELSE 0 END)    AS [QC],       -- QC
                            SUM(D.Acq_Length_Minutes / 60.0 / 24.0) AS [Total_AcqTimeDays],             -- Total time acquiring data, in days
                            SUM(CASE WHEN D.Dataset_Num LIKE 'Blank%' OR D.Dataset_Num LIKE 'QC%'
                                     THEN D.Acq_Length_Minutes / 60.0 / 24.0 Else 0 End) AS [BadBlankQC_AcqTimeDays],

                            -- EMSL Funded Counts:
                            SUM(DF.EMSL_Funded) AS [EF_Total],                                                          -- EF_Total
                            0 AS [EF_Bad],                                                                              -- EF_Bad
                            SUM(CASE WHEN D.Dataset_Num LIKE 'Blank%' THEN DF.EMSL_Funded ELSE 0 END) AS [EF_Blank],    -- EF_Blank
                            SUM(CASE WHEN D.Dataset_Num LIKE 'QC%' THEN DF.EMSL_Funded ELSE 0 END) AS [EF_QC],          -- EF_QC
                            SUM(CASE WHEN DF.EMSL_Funded = 1 THEN D.Acq_Length_Minutes / 60.0 / 24.0 Else 0 End) AS [EF_Total_AcqTimeDays], -- EF Total time acquiring data, in days
                            SUM(CASE WHEN DF.EMSL_Funded = 1 And (D.Dataset_Num LIKE 'Blank%' OR D.Dataset_Num LIKE 'QC%')
                                     THEN D.Acq_Length_Minutes / 60.0 / 24.0 Else 0 End) AS [EF_BadBlankQC_AcqTimeDays]

                        FROM
                            #Tmp_Datasets DF INNER JOIN
                            T_Dataset D ON DF.Dataset_ID = D.Dataset_ID INNER JOIN
                            T_Instrument_Name I ON D.DS_instrument_name_ID = I.Instrument_ID INNER JOIN
                            #Tmp_CampaignFilter CF ON CF.Campaign_ID = DF.Campaign_ID
                        WHERE NOT ( D.Dataset_Num LIKE 'Bad%' OR
                                    D.DS_Rating IN (-1,-2,-5) OR
                                    D.DS_State_ID = 4
                                ) AND
                            (I.IN_operations_role = 'Production' OR @productionOnly = 0)
                        GROUP BY I.IN_Name, I.Percent_EMSL_Owned, DF.Proposal_Type
                        UNION
                        -- Select Bad or Not Released datasets
                        SELECT
                            I.IN_Name as Instrument,
                            I.Percent_EMSL_Owned,
                            DF.Proposal_Type,
                            COUNT(*) AS [Total],                                                            -- Total
                            SUM(CASE WHEN D.Dataset_Num NOT LIKE 'Blank%' THEN 1 ELSE 0 END) AS [Bad],      -- Bad (not blank)
                            SUM(CASE WHEN D.Dataset_Num LIKE 'Blank%' THEN 1 ELSE 0 END)     AS [Blank],    -- Bad Blank; will be counted as a blank
                            0                                                                AS [QC],       -- Bad QC; simply counted as [Bad]
                            SUM(D.Acq_Length_Minutes / 60.0 / 24.0) AS [Total_AcqTimeDays],                 -- Total time acquiring data, in days
                            SUM(D.Acq_Length_Minutes / 60.0 / 24.0) AS [BadBlankQC_AcqTimeDays],

                            -- EMSL Funded Counts:
                            SUM(DF.EMSL_Funded) AS [EF_Total],                                                          -- EF_Total
                            SUM(CASE WHEN D.Dataset_Num NOT LIKE 'Blank%' THEN DF.EMSL_Funded ELSE 0 END) AS [EF_Bad],  -- EF_Bad (not blank)
                            SUM(CASE WHEN D.Dataset_Num LIKE 'Blank%' THEN DF.EMSL_Funded ELSE 0 END) AS [EF_Blank],    -- Bad EF_Blank; will be counted as a blank
                            0                                                                         AS [EF_QC],       -- Bad EF_QC; simply counted as [Bad]
                            SUM(CASE WHEN DF.EMSL_Funded = 1 THEN D.Acq_Length_Minutes / 60.0 / 24.0 Else 0 End) AS [EF_Total_AcqTimeDays], -- EF Total time acquiring data, in days
                            SUM(CASE WHEN DF.EMSL_Funded = 1 THEN D.Acq_Length_Minutes / 60.0 / 24.0 Else 0 End) AS [EF_BadBlankQC_AcqTimeDays]
                        FROM
                            #Tmp_Datasets DF INNER JOIN
                            T_Dataset D ON DF.Dataset_ID = D.Dataset_ID INNER JOIN
                            T_Instrument_Name I ON D.DS_instrument_name_ID = I.Instrument_ID INNER JOIN
                            #Tmp_CampaignFilter CF ON CF.Campaign_ID = DF.Campaign_ID
                        WHERE ( D.Dataset_Num LIKE 'Bad%' OR
                                D.DS_Rating IN (-1,-2,-5) OR
                                D.DS_State_ID = 4
                              ) AND
                              (I.IN_operations_role = 'Production' OR @productionOnly = 0)
                        GROUP BY I.IN_Name, I.Percent_EMSL_Owned, DF.Proposal_Type
                    ) StatsQ
                GROUP BY Instrument, Percent_EMSL_Owned, Proposal_Type
                ) CombinedStatsQ
            ) OuterQ
        ORDER BY Instrument, proposal_type

    End
    Else
    Begin

        SELECT
            Instrument AS instrument,
            [Total] AS total_datasets,
            @daysInRange AS days_in_range,
            Convert(decimal(5,1), [Total]/@daysInRange) AS datasets_per_day,
            [Blank] AS blank_datasets,
            [QC] AS qc_datasets,
            -- [TS] as troubleshooting,
            [Bad] as bad_datasets,
            [Study Specific] AS study_specific_datasets,
            Convert(decimal(5,1), [Study Specific] / @daysInRange) AS study_specific_datasets_per_day,
            [EF Study Specific] AS emsl_funded_study_specific_datasets,
            Convert(decimal(5,1), [EF Study Specific] / @daysInRange) AS ef_study_specific_datasets_per_day,

            Convert(decimal(5,1), [Total_AcqTimeDays]) AS total_acq_time_days,
            Convert(decimal(5,1), [Study_Specific_AcqTimeDays]) AS study_specific_acq_time_days,
            Convert(decimal(5,1), [EF_Total_AcqTimeDays]) AS ef_total_acq_time_days,
            Convert(decimal(5,1), [EF_Study_Specific_AcqTimeDays]) AS ef_study_specific_acq_time_days,
            Convert(decimal(5,1), [Hours_AcqTime_per_Day]) as hours_acq_time_per_day,

            Instrument AS inst_,                        -- The website will show this column as "Inst."
            Percent_EMSL_Owned AS pct_inst_emsl_owned,

            -- EMSL Funded Counts:
            Convert(float, Convert(decimal(9,2), [EF_Total])) AS ef_total_datasets,
            Convert(decimal(5,1), [EF_Total]/@daysInRange) AS ef_datasets_per_day,
            -- Convert(float, Convert(decimal(9,2), [EF_Blank])) AS ef_blank_datasets,
            -- Convert(float, Convert(decimal(9,2), [EF_QC])) AS ef_qc_datasets,
            -- Convert(float, Convert(decimal(9,2), [EF_Bad])) as ef_bad_datasets,

            Convert(decimal(5,1), ([Blank] * 100.0 / [Total])) AS pct_blank_datasets,
            Convert(decimal(5,1), ([QC] * 100.0 / [Total])) AS pct_qc_datasets,
            Convert(decimal(5,1), ([Bad] * 100.0 / [Total])) AS pct_bad_datasets,
            -- Convert(decimal(5,1), ([Reruns] * 100.0 / [Total])) AS pct_reruns,
            Convert(decimal(5,1), ([Study Specific] * 100.0 / [Total])) AS pct_study_specific_datasets,
            CASE WHEN [Total] > 0 THEN Convert(decimal(5,1), [EF Study Specific] * 100.0 / [Total]) ELSE NULL END AS pct_ef_study_specific_datasets,
            CASE WHEN [Total_AcqTimeDays] > 0 THEN Convert(decimal(5,1), [EF_Total_AcqTimeDays] * 100.0 / [Total_AcqTimeDays]) ELSE NULL END AS pct_ef_study_specific_by_acq_time,

            Instrument AS inst
        FROM (
            SELECT Instrument, Percent_EMSL_Owned,
                [Total], [Bad], [Blank], [QC],
                [Total] - ([Blank] + [QC] + [Bad]) AS [Study Specific],
                [Total_AcqTimeDays],
                [Total_AcqTimeDays] - [BadBlankQC_AcqTimeDays] AS [Study_Specific_AcqTimeDays],

                Case When @daysInRange > 0.5 Then [Total_AcqTimeDays] / @daysInRange * 24 Else Null End AS [Hours_AcqTime_per_Day],

                [EF_Total], [EF_Bad], [EF_Blank], [EF_QC],
                [EF_Total] - ([EF_Blank] + [EF_QC] + [EF_Bad]) AS [EF Study Specific],
                [EF_Total_AcqTimeDays],
                [EF_Total_AcqTimeDays] - [EF_BadBlankQC_AcqTimeDays] AS [EF_Study_Specific_AcqTimeDays]

            FROM
                (SELECT Instrument,
                        Percent_EMSL_Owned,
                        SUM([Total]) AS [Total],        -- Total (Good + bad)
                        SUM([Bad]) AS [Bad],            -- Bad (not blank)
                        SUM([Blank]) AS [Blank],        -- Blank (Good + bad)
                        SUM([QC]) AS [QC],              -- QC (not bad)

                        Sum([Total_AcqTimeDays]) AS [Total_AcqTimeDays],            -- Total time acquiring data
                        Sum([BadBlankQC_AcqTimeDays]) AS [BadBlankQC_AcqTimeDays],  -- Total time acquiring bad/blank/QC data

                        -- EMSL Funded (EF) Counts:
                        Sum([EF_Total]) AS [EF_Total],        -- EF Total (Good + bad)
                        Sum([EF_Bad]) AS [EF_Bad],            -- EF Bad (not blank)
                        Sum([EF_Blank]) AS [EF_Blank],        -- EF Blank (Good + bad)
                        Sum([EF_QC]) AS [EF_QC],              -- EF QC (not bad)

                        Sum([EF_Total_AcqTimeDays]) AS [EF_Total_AcqTimeDays],                 -- EF Total time acquiring data
                        Sum([EF_BadBlankQC_AcqTimeDays]) AS [EF_BadBlankQC_AcqTimeDays]        -- EF Total time acquiring bad/blank/QC data

                FROM
                    (    -- Select Good datasets (excluded Bad, Not Released, Unreviewed, etc.)
                        SELECT
                            I.IN_Name as Instrument,
                            I.Percent_EMSL_Owned,
                            COUNT(*) AS [Total],                                                        -- Total
                            0                                                            AS [Bad],      -- Bad
                            SUM(CASE WHEN D.Dataset_Num LIKE 'Blank%' THEN 1 ELSE 0 END) AS [Blank],    -- Blank
                            SUM(CASE WHEN D.Dataset_Num LIKE 'QC%' THEN 1 ELSE 0 END)    AS [QC],       -- QC
                            SUM(D.Acq_Length_Minutes / 60.0 / 24.0) AS [Total_AcqTimeDays],             -- Total time acquiring data, in days
                            SUM(CASE WHEN D.Dataset_Num LIKE 'Blank%' OR D.Dataset_Num LIKE 'QC%'
                                     THEN D.Acq_Length_Minutes / 60.0 / 24.0 Else 0 End) AS [BadBlankQC_AcqTimeDays],

                            -- EMSL Funded Counts:
                            SUM(DF.EMSL_Funded) AS [EF_Total],                                                          -- EF_Total
                            0 AS [EF_Bad],                                                                              -- EF_Bad
                            SUM(CASE WHEN D.Dataset_Num LIKE 'Blank%' THEN DF.EMSL_Funded ELSE 0 END) AS [EF_Blank],    -- EF_Blank
                            SUM(CASE WHEN D.Dataset_Num LIKE 'QC%' THEN DF.EMSL_Funded ELSE 0 END) AS [EF_QC],          -- EF_QC
                            SUM(CASE WHEN DF.EMSL_Funded = 1 THEN D.Acq_Length_Minutes / 60.0 / 24.0 Else 0 End) AS [EF_Total_AcqTimeDays], -- EF Total time acquiring data, in days
                            SUM(CASE WHEN DF.EMSL_Funded = 1 And (D.Dataset_Num LIKE 'Blank%' OR D.Dataset_Num LIKE 'QC%')
                                     THEN D.Acq_Length_Minutes / 60.0 / 24.0 Else 0 End) AS [EF_BadBlankQC_AcqTimeDays]

                        FROM
                            #Tmp_Datasets DF INNER JOIN
                            T_Dataset D ON DF.Dataset_ID = D.Dataset_ID INNER JOIN
                            T_Instrument_Name I ON D.DS_instrument_name_ID = I.Instrument_ID INNER JOIN
                            #Tmp_CampaignFilter CF ON CF.Campaign_ID = DF.Campaign_ID
                        WHERE NOT ( D.Dataset_Num LIKE 'Bad%' OR
                                    D.DS_Rating IN (-1,-2,-5) OR
                                    D.DS_State_ID = 4
                                ) AND
                            (I.IN_operations_role = 'Production' OR @productionOnly = 0)
                        GROUP BY I.IN_Name, I.Percent_EMSL_Owned
                        UNION
                        -- Select Bad or Not Released datasets
                        SELECT
                            I.IN_Name as Instrument,
                            I.Percent_EMSL_Owned,
                            COUNT(*) AS [Total],                                                            -- Total
                            SUM(CASE WHEN D.Dataset_Num NOT LIKE 'Blank%' THEN 1 ELSE 0 END) AS [Bad],      -- Bad (not blank)
                            SUM(CASE WHEN D.Dataset_Num LIKE 'Blank%' THEN 1 ELSE 0 END)     AS [Blank],    -- Bad Blank; will be counted as a blank
                            0                                                                AS [QC],       -- Bad QC; simply counted as [Bad]
                            SUM(D.Acq_Length_Minutes / 60.0 / 24.0) AS [Total_AcqTimeDays],                 -- Total time acquiring data, in days
                            SUM(D.Acq_Length_Minutes / 60.0 / 24.0) AS [BadBlankQC_AcqTimeDays],

                            -- EMSL Funded Counts:
                            SUM(DF.EMSL_Funded) AS [EF_Total],                                                          -- EF_Total
                            SUM(CASE WHEN D.Dataset_Num NOT LIKE 'Blank%' THEN DF.EMSL_Funded ELSE 0 END) AS [EF_Bad],  -- EF_Bad (not blank)
                            SUM(CASE WHEN D.Dataset_Num LIKE 'Blank%' THEN DF.EMSL_Funded ELSE 0 END) AS [EF_Blank],    -- Bad EF_Blank; will be counted as a blank
                            0                                                                         AS [EF_QC],       -- Bad EF_QC; simply counted as [Bad]
                            SUM(CASE WHEN DF.EMSL_Funded = 1 THEN D.Acq_Length_Minutes / 60.0 / 24.0 Else 0 End) AS [EF_Total_AcqTimeDays], -- EF Total time acquiring data, in days
                            SUM(CASE WHEN DF.EMSL_Funded = 1 THEN D.Acq_Length_Minutes / 60.0 / 24.0 Else 0 End) AS [EF_BadBlankQC_AcqTimeDays]
                        FROM
                            #Tmp_Datasets DF INNER JOIN
                            T_Dataset D ON DF.Dataset_ID = D.Dataset_ID INNER JOIN
                            T_Instrument_Name I ON D.DS_instrument_name_ID = I.Instrument_ID INNER JOIN
                            #Tmp_CampaignFilter CF ON CF.Campaign_ID = DF.Campaign_ID
                        WHERE ( D.Dataset_Num LIKE 'Bad%' OR
                                D.DS_Rating IN (-1,-2,-5) OR
                                D.DS_State_ID = 4
                            ) AND
                            (I.IN_operations_role = 'Production' OR @productionOnly = 0)
                        GROUP BY I.IN_Name, I.Percent_EMSL_Owned
                    ) StatsQ
                GROUP BY Instrument, Percent_EMSL_Owned
                ) CombinedStatsQ
            ) OuterQ
        ORDER BY Instrument

    End

    END TRY
    BEGIN CATCH
        EXEC format_error_message @message output, @myError output

        -- rollback any open transactions
        IF (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;

        Exec post_log_entry 'Error', @message, 'report_production_stats'
    END CATCH

    RETURN @myError

GO
GRANT VIEW DEFINITION ON [dbo].[report_production_stats] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[report_production_stats] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[report_production_stats] TO [Limited_Table_Write] AS [dbo]
GO
