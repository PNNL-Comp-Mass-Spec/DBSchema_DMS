/****** Object:  StoredProcedure [dbo].[StoreProjectUsageStats] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure [dbo].[StoreProjectUsageStats]
/****************************************************
**
**  Desc: 
**      Stores new stats in T_Project_Usage_Stats,
**      tracking the number of datasets and user-initiated analysis jobs
**      run within the specified date range
**
**      This procedure is called weekly at 3 am on Friday morning
**      to auto-update the stats
**        
**  Auth:   mem
**  Date:   12/18/2015 mem - Initial version
**          05/06/2016 mem - Now tracking experiments
**          02/24/2017 mem - Update the Merge logic to join on Proposal_User
**          08/02/2018 mem - T_Sample_Prep_Request now tracks EUS User ID as an integer
**    
*****************************************************/
(    
    @WindowDays int = 7,
    @EndDate smalldatetime = null,            -- End date/time; if null, uses the current date/time
    @infoOnly tinyint = 1
)
AS
    Set NoCount On

    Declare @myRowCount int = 0
    Declare @myError int = 0
    
    -----------------------------------------
    -- Validate the input parameters
    -----------------------------------------
    
    Set @WindowDays = IsNull(@WindowDays, 7)
    If (@WindowDays < 1)
        Set @WindowDays = 1
    
    Set @EndDate = IsNull(@EndDate, GetDate())
    Set @infoOnly = IsNull(@infoOnly, 0)

    -- Round @EndDate backward to the nearest hour
    Set @EndDate = DateAdd(Hour, DatePart(Hour, @EndDate), Cast(Cast(@EndDate as Date) AS smalldatetime))

    Declare @StartDate smalldatetime = DateAdd(day, -@WindowDays, @EndDate)

    Declare @EndDateYear int = DatePart(year, @EndDate)
    Declare @EndDateWeek tinyint = DatePart(week, @EndDate)

    -----------------------------------------
    -- Create a temporary table
    -----------------------------------------

    CREATE TABLE #Tmp_Project_Usage_Stats(
        Entry_ID int IDENTITY(1,1) NOT NULL,
        StartDate smalldatetime NOT NULL,
        EndDate smalldatetime NOT NULL,
        TheYear int NOT NULL,
        WeekOfYear tinyint NOT NULL,
        Proposal_ID varchar(10) NULL,
        RDS_WorkPackage varchar(50) NULL,
        Proposal_Active int NOT NULL,
        Project_Type_ID tinyint NOT NULL,
        Samples int not NULL,
        Datasets int not NULL,
        Jobs int not NULL,
        EUS_UsageType smallint NOT NULL,
        Proposal_Type varchar(100) NULL,
        Proposal_User varchar(128) NULL,
        Instrument_First varchar(32) NULL,
        Instrument_Last varchar(32) NULL,
        JobTool_First varchar(64) NULL,
        JobTool_Last varchar(64) NULL,
    )

    -----------------------------------------
    -- Find datasets run within the date range
    -----------------------------------------
    --
    INSERT INTO #Tmp_Project_Usage_Stats( StartDate,
                                          EndDate,
                                          TheYear,
                                          WeekOfYear,
                                          Proposal_ID,
                                          RDS_WorkPackage,
                                          Proposal_Active,
                                          Project_Type_ID,
                                          Samples,
                                          Datasets,
                                          Jobs,
                                          EUS_UsageType,
                                          Proposal_Type,
                                          Proposal_User,
                                          Instrument_First,
                                          Instrument_Last,
                                          JobTool_First,
                                          JobTool_Last )
    SELECT @Startdate AS StartDate,
           @EndDate AS EndDate,
           @EndDateYear AS TheYear,
           @EndDateWeek AS WeekOfYear,
           EUSPro.Proposal_ID,
           RR.RDS_WorkPackage,
           CASE
               WHEN GetDate() >= EUSPro.Proposal_Start_Date AND
                    GetDate() <= EUSPro.Proposal_End_Date THEN 1
               ELSE 0
           END AS Proposal_Active,
           CASE
               WHEN EUSPro.Proposal_Type IN ('RESOURCE_OWNER') THEN 1                                           -- Resource_Owner
               WHEN EUSPro.Proposal_Type IN ('PROPRIETARY', 'PROPRIETARY_PUBLIC') THEN 2                        -- Proprietary
               WHEN EUSPro.Proposal_Type NOT IN ('PROPRIETARY', 'RESOURCE_OWNER', 'PROPRIETARY_PUBLIC') THEN 3  -- EMSL_User
              ELSE 0                                                                                            -- Unknown
           END AS Project_Type_ID,
           0 AS Samples,
           COUNT(*) AS Datasets,
           0 AS Jobs,
           RR.RDS_EUS_UsageType AS EUS_UsageType,
           EUSPro.Proposal_Type,
           Min(EUSUsers.NAME_FM) AS Proposal_User,
           Min(InstName.IN_name) AS Instrument_First,
           Max(InstName.IN_name) AS Instrument_Last,
           Cast(NULL AS varchar(64)) AS JobTool_First,
           Cast(NULL AS varchar(64)) AS JobTool_Last
    FROM T_Instrument_Name InstName
         INNER JOIN T_Dataset DS
                    INNER JOIN T_Requested_Run RR
                      ON DS.Dataset_ID = RR.DatasetID
           ON InstName.Instrument_ID = DS.DS_instrument_name_ID
         LEFT OUTER JOIN T_EUS_Users EUSUsers
                         INNER JOIN T_Requested_Run_EUS_Users RRUsers
                           ON EUSUsers.PERSON_ID = RRUsers.EUS_Person_ID
           ON RR.ID = RRUsers.Request_ID
         LEFT OUTER JOIN T_EUS_Proposals EUSPro
           ON RR.RDS_EUS_Proposal_ID = EUSPro.Proposal_ID
    WHERE DS.DS_created BETWEEN @StartDate AND @EndDate
    GROUP BY EUSPro.Proposal_ID, RR.RDS_WorkPackage, RR.RDS_EUS_UsageType, EUSPro.Proposal_Type,
             EUSPro.Proposal_Start_Date, EUSPro.Proposal_End_Date
    ORDER BY Count(*) DESC

    -----------------------------------------
    -- Find user-initiated analysis jobs started within the date range
    -- Store in T_Project_Usage_Stats via a merge
    -----------------------------------------
    --
    MERGE #Tmp_Project_Usage_Stats AS t
    USING (
        SELECT @Startdate AS StartDate,
               @EndDate AS EndDate,
               @EndDateYear AS TheYear,
               @EndDateWeek AS WeekOfYear,
               EUSPro.Proposal_ID,
               RR.RDS_WorkPackage,
               CASE
                   WHEN GetDate() >= EUSPro.Proposal_Start_Date AND
                        GetDate() <= EUSPro.Proposal_End_Date THEN 1
                   ELSE 0
               END AS Proposal_Active,
          CASE
              WHEN EUSPro.Proposal_Type IN ('RESOURCE_OWNER') THEN 1                                            -- Resource_Owner
              WHEN EUSPro.Proposal_Type IN ('PROPRIETARY', 'PROPRIETARY_PUBLIC') THEN 2                         -- Proprietary
              WHEN EUSPro.Proposal_Type NOT IN ('PROPRIETARY', 'RESOURCE_OWNER', 'PROPRIETARY_PUBLIC') THEN 3   -- EMSL_User
              ELSE 0                                                                                            -- Unknown
          END AS Project_Type_ID,
               0 AS Samples,              
               0 AS Datasets,
               Count(*) AS Jobs,
               RR.RDS_EUS_UsageType AS EUS_UsageType,
               EUSPro.Proposal_Type,
               Min(EUSUsers.NAME_FM) AS Proposal_User,
               Min(InstName.IN_name) AS Instrument_First,
               Max(InstName.IN_name) AS Instrument_Last,
               Min(AnTool.AJT_toolName) AS JobTool_First,
               Max(AnTool.AJT_toolName) AS JobTool_Last
        FROM T_Instrument_Name InstName
             INNER JOIN T_Dataset DS
                        INNER JOIN T_Requested_Run RR
                          ON DS.Dataset_ID = RR.DatasetID
                        INNER JOIN T_Analysis_Job J
                          ON J.AJ_datasetID = DS.Dataset_ID AND
                             J.AJ_start BETWEEN @StartDate AND @EndDate
                        INNER JOIN T_Analysis_Job_Request AJR
                          ON AJR.AJR_requestID = J.AJ_requestID AND
                             AJR.AJR_requestID > 1
                        INNER JOIN T_Analysis_Tool AnTool
                          ON J.AJ_analysisToolID = AnTool.AJT_toolID
               ON InstName.Instrument_ID = DS.DS_instrument_name_ID
             LEFT OUTER JOIN T_EUS_Users EUSUsers
                             INNER JOIN T_Requested_Run_EUS_Users RRUsers
                               ON EUSUsers.PERSON_ID = RRUsers.EUS_Person_ID
               ON RR.ID = RRUsers.Request_ID
             LEFT OUTER JOIN T_EUS_Proposals EUSPro
               ON RR.RDS_EUS_Proposal_ID = EUSPro.Proposal_ID
        GROUP BY EUSPro.Proposal_ID, RR.RDS_WorkPackage, RR.RDS_EUS_UsageType, EUSPro.Proposal_Type,
                 EUSPro.Proposal_Start_Date, EUSPro.Proposal_End_Date
    ) AS s
    ON ( t.TheYear = s.TheYear AND 
         t.WeekOfYear = s.WeekOfYear AND
         IsNull(t.Proposal_ID, 0) = IsNull(s.Proposal_ID, 0) AND
         t.RDS_WorkPackage = s.RDS_WorkPackage AND
         t.EUS_UsageType = s.EUS_UsageType AND
         IsNull(t.Proposal_User, '') = IsNull(s.Proposal_User, ''))
    WHEN MATCHED AND (
        ISNULL( NULLIF(t.Jobs, s.Jobs),
                NULLIF(s.Jobs, t.Jobs)) IS NOT NULL
        )
    THEN UPDATE Set 
        Jobs = s.Jobs,
        JobTool_First = s.JobTool_First,
        JobTool_Last = s.JobTool_Last
    WHEN NOT MATCHED BY TARGET THEN
        INSERT(StartDate, EndDate, TheYear, WeekOfYear, Proposal_ID, 
              RDS_WorkPackage, Proposal_Active, Project_Type_ID, 
              Samples, Datasets, Jobs, EUS_UsageType, Proposal_Type, Proposal_User, 
              Instrument_First, Instrument_Last, 
              JobTool_First, JobTool_Last)
        VALUES(s.StartDate, s.EndDate, s.TheYear, s.WeekOfYear, s.Proposal_ID, 
               s.RDS_WorkPackage, s.Proposal_Active, s.Project_Type_ID, 
               s.Samples, s.Datasets, s.Jobs, s.EUS_UsageType, s.Proposal_Type, s.Proposal_User, 
               s.Instrument_First, s.Instrument_Last, 
               s.JobTool_First, s.JobTool_Last) ;


    -----------------------------------------
    -- Find experiments (samples) prepared within the date range
    -- Store in T_Project_Usage_Stats via a merge
    -----------------------------------------
    --
    MERGE #Tmp_Project_Usage_Stats AS t
    USING (
        SELECT @Startdate AS StartDate,
               @EndDate AS EndDate,
               @EndDateYear AS TheYear,
               @EndDateWeek AS WeekOfYear,
               EUSPro.Proposal_ID,
               SPR.Work_Package_Number,
               CASE
                   WHEN GetDate() >= EUSPro.Proposal_Start_Date AND
                        GetDate() <= EUSPro.Proposal_End_Date THEN 1
                   ELSE 0
               END AS Proposal_Active,
               CASE
                   WHEN EUSPro.Proposal_Type IN ('RESOURCE_OWNER') THEN 1                                            -- Resource_Owner
                   WHEN EUSPro.Proposal_Type IN ('PROPRIETARY', 'PROPRIETARY_PUBLIC') THEN 2                         -- Proprietary
                   WHEN EUSPro.Proposal_Type NOT IN ('PROPRIETARY', 'RESOURCE_OWNER', 'PROPRIETARY_PUBLIC') THEN 3   -- EMSL_User
                   ELSE 0                                                                                            -- Unknown
               END AS Project_Type_ID,
               COUNT(DISTINCT Exp_ID) AS Samples,
               0 AS Datasets,
               0 AS Jobs,
               UsageType.ID AS EUS_UsageType,
               EUSPro.Proposal_Type,
               Min(EUSUsers.NAME_FM) AS Proposal_User,
               '' AS Instrument_First,
               '' AS Instrument_Last,
               '' AS JobTool_First,
               '' AS JobTool_Last
        FROM T_Sample_Prep_Request SPR
             INNER JOIN T_EUS_Proposals EUSPro
               ON SPR.EUS_Proposal_ID = EUSPro.Proposal_ID
             INNER JOIN T_EUS_UsageType UsageType
               ON SPR.EUS_UsageType = UsageType.Name
             LEFT OUTER JOIN T_Experiments
               ON SPR.ID = T_Experiments.EX_sample_prep_request_ID          
             LEFT OUTER JOIN T_EUS_Users AS EUSUsers 
               ON SPR.EUS_User_ID = EUSUsers.Person_ID
        WHERE T_Experiments.EX_created BETWEEN @StartDate and @EndDate
        GROUP BY EUSPro.Proposal_ID, SPR.Work_Package_Number, EUSPro.Proposal_Start_Date, EUSPro.Proposal_End_Date,
                 EUSPro.Proposal_Type, SPR.EUS_User_ID, UsageType.ID
    ) AS s
    ON ( t.TheYear = s.TheYear AND 
         t.WeekOfYear = s.WeekOfYear AND
         IsNull(t.Proposal_ID, 0) = IsNull(s.Proposal_ID, 0) AND
         t.RDS_WorkPackage = s.Work_Package_Number AND
         t.EUS_UsageType = s.EUS_UsageType AND
         IsNull(t.Proposal_User, '') = IsNull(s.Proposal_User, ''))
    WHEN MATCHED AND (
        ISNULL( NULLIF(t.Samples, s.Samples),
                NULLIF(s.Samples, t.Samples)) IS NOT NULL
        )
    THEN UPDATE Set 
        Samples = s.Samples
    WHEN NOT MATCHED BY TARGET THEN
        INSERT(StartDate, EndDate, TheYear, WeekOfYear, Proposal_ID, 
              RDS_WorkPackage, Proposal_Active, Project_Type_ID, 
              Samples, Datasets, Jobs, EUS_UsageType, Proposal_Type, Proposal_User, 
              Instrument_First, Instrument_Last, 
              JobTool_First, JobTool_Last)
        VALUES(s.StartDate, s.EndDate, s.TheYear, s.WeekOfYear, s.Proposal_ID, 
               s.Work_Package_Number, s.Proposal_Active, s.Project_Type_ID, 
               s.Samples, s.Datasets, s.Jobs, s.EUS_UsageType, s.Proposal_Type, s.Proposal_User, 
               s.Instrument_First, s.Instrument_Last, 
               s.JobTool_First, s.JobTool_Last) ;



    If @infoOnly <> 0
    Begin
        SELECT Stats.Entry_ID,
               Stats.StartDate,
               Stats.EndDate,
               Stats.TheYear,
               Stats.WeekOfYear,
               Stats.Proposal_ID,
               Stats.RDS_WorkPackage,
               Stats.Proposal_Active,
               ProjectTypes.Project_Type_Name,
               Stats.Samples,
               Stats.Datasets,
               Stats.Jobs,
               EUSUsage.Name AS UsageType,
               Stats.Proposal_Type,
               Stats.Proposal_User,
               Proposals.Title AS Proposal_Title,
               Stats.Instrument_First,
               Stats.Instrument_Last,
               Stats.JobTool_First,
               Stats.JobTool_Last,
               Cast(Proposals.Proposal_Start_Date AS date) AS Proposal_Start_Date,
               Cast(Proposals.Proposal_End_Date AS date) AS Proposal_End_Date
        FROM #Tmp_Project_Usage_Stats Stats
             INNER JOIN T_Project_Usage_Types ProjectTypes
               ON Stats.Project_Type_ID = ProjectTypes.Project_Type_ID
             INNER JOIN T_EUS_UsageType EUSUsage
               ON Stats.EUS_UsageType = EUSUsage.ID
             LEFT OUTER JOIN T_EUS_Proposals Proposals
               ON Stats.Proposal_ID = Proposals.Proposal_ID
        ORDER BY Datasets DESC, Jobs DESC, Samples Desc

    End
    Else
    Begin
        DELETE FROM T_Project_Usage_Stats
        WHERE TheYear = @EndDateYear AND
              WeekOfYear = @EndDateWeek AND
              Cast(EndDate AS date) = Cast(@EndDate AS date)


        INSERT INTO T_Project_Usage_Stats( StartDate,
                                           EndDate,
                                           TheYear,
                                           WeekOfYear,
                                           Proposal_ID,
                                           RDS_WorkPackage,
                                           Proposal_Active,
                                           Project_Type_ID,
                                           Samples,
                                           Datasets,
                                           Jobs,
                                           EUS_UsageType,
                                           Proposal_Type,
                                           Proposal_User,
                                           Instrument_First,
                                           Instrument_Last,
                                           JobTool_First,
                                           JobTool_Last )
        SELECT StartDate,
               EndDate,
               TheYear,
               WeekOfYear,
               Proposal_ID,
               RDS_WorkPackage,
               Proposal_Active,
               Project_Type_ID,
               Samples,
               Datasets,
               Jobs,
               EUS_UsageType,
               Proposal_Type,
               Proposal_User,
               Instrument_First,
               Instrument_Last,
               JobTool_First,
               JobTool_Last
        FROM #Tmp_Project_Usage_Stats
        ORDER BY Datasets DESC, Jobs DESC

    End

    
Done:
    
    --
    Return @myError


GO
GRANT VIEW DEFINITION ON [dbo].[StoreProjectUsageStats] TO [DDL_Viewer] AS [dbo]
GO
