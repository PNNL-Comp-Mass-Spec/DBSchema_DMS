/****** Object:  StoredProcedure [dbo].[UpdateCachedStatistics] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[UpdateCachedStatistics]
/****************************************************
**
**  Desc:
**      Updates various cached statistics
**      - Job_Usage_Count in T_Param_Files
**      - Job_Usage_Count in T_Settings_Files
**      - Job_Count in T_Analysis_Job_Request
**      - Job_Usage_Count in T_Protein_Collection_Usage
**      - Dataset usage stats in T_Cached_Instrument_Dataset_Type_Usage
**      - Dataset usage stats in T_Instrument_Group_Allowed_DS_Type
**      - Dataset usage stats in T_LC_Cart_Configuration
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**  Date:   11/04/2008 mem - Initial version (Ticket: #698)
**          12/21/2009 mem - Add parameter @updateJobRequestStatistics
**          10/20/2011 mem - Now considering analysis tool name when updated T_Param_Files and T_Settings_Files
**          09/11/2012 mem - Now updating T_Protein_Collection_Usage by calling UpdateProteinCollectionUsage
**          07/18/2016 mem - Now updating Job_Usage_Last_Year in T_Param_Files and T_Settings_Files
**          02/23/2017 mem - Update dataset usage in T_LC_Cart_Configuration
**          08/30/2018 mem - Tabs to spaces
**          07/14/2022 mem - Update dataset usage in T_Instrument_Group_Allowed_DS_Type
**                         - Update dataset usage in T_Cached_Instrument_Dataset_Type_Usage
**                         - Add parameter @showRuntimeStats
**                         - Only update counts if they change
**
*****************************************************/
(
    @message varchar(512) = '' output,
    @previewSql tinyint = 0,                        -- When non-zero, preview the SQL used to compile stats for T_General_Statistics
    @updateParamSettingsFileCounts tinyint = 1,     -- When non-zero, update cached counts in T_Param_Files, T_Settings_Files, T_Cached_Instrument_Dataset_Type_Usage, T_Instrument_Group_Allowed_DS_Type, and T_LC_Cart_Configuration
    @updateGeneralStatistics tinyint = 1,           -- When non-zero, update T_General_Statistics
    @updateJobRequestStatistics tinyint = 1 ,       -- When non-zero, update T_Analysis_Job_Request
    @showRuntimeStats tinyint = 0
)
As
    Set nocount on

    Declare @myRowCount int = 0
    Declare @myError int = 0

    Declare @UniqueID int
    Declare @Category varchar(128)
    Declare @Label varchar(128)
    Declare @UseDecimal tinyint

    Declare @Sql nvarchar(2048)
    Declare @SqlParams nvarchar(128)
    Declare @SqlParamsDec nvarchar(128)

    Declare @Total int
    Declare @TotalDec decimal(18, 3)
    Declare @Value varchar(128)

    Declare @Continue int

    ------------------------------------------------
    -- Validate the inputs
    ------------------------------------------------
    --
    Set @message = ''
    Set @previewSql = Coalesce(@previewSql, 0)
    Set @updateParamSettingsFileCounts = Coalesce(@updateParamSettingsFileCounts, 1)
    Set @updateGeneralStatistics = Coalesce(@updateGeneralStatistics, 0)
    Set @updateJobRequestStatistics = Coalesce(@updateJobRequestStatistics, 1)
    Set @showRuntimeStats = Coalesce(@showRuntimeStats, 0)

    CREATE TABLE #Tmp_Update_Stats (
        Entry_ID        int Identity(1,1),
        Task            varchar(128),
        Runtime_Seconds float
    )

    Declare @startTime Datetime

    If @updateParamSettingsFileCounts <> 0
    Begin -- <a1>
        ------------------------------------------------
        -- Update Usage Counts for Parameter Files
        ------------------------------------------------
        --
        Declare @thresholdOneYear datetime = DateAdd(month, -12, GetDate())

        Set @startTime = GetDate()

        UPDATE T_Param_Files
        SET Job_Usage_Count = Coalesce(StatsQ.JobCount, 0),
            Job_Usage_Last_Year = Coalesce(StatsQ.JobCountLastYear, 0)        -- Usage over the last 12 months
        FROM T_Param_Files PF
             LEFT OUTER JOIN ( SELECT AJ.AJ_parmFileName AS Param_File_Name,
                                      PFT.Param_File_Type_ID,
                                      COUNT(*) AS JobCount,
                                      SUM(CASE
                                              WHEN AJ_Created >= @thresholdOneYear THEN 1
                                              ELSE 0
                                          END) AS JobCountLastYear
                               FROM T_Analysis_Job AJ
                                    INNER JOIN T_Analysis_Tool AnTool
                                      ON AJ.AJ_analysisToolID = AnTool.AJT_toolID
                                    INNER JOIN T_Param_File_Types PFT
                                      ON AnTool.AJT_paramFileType = PFT.Param_File_Type_ID
                               GROUP BY AJ.AJ_parmFileName, PFT.Param_File_Type_ID
                              ) StatsQ
               ON PF.Param_File_Name = StatsQ.Param_File_Name AND
                  PF.Param_File_Type_ID = StatsQ.Param_File_Type_ID
        WHERE Coalesce(Job_Usage_Count, 0) <> Coalesce(StatsQ.JobCount, 0) OR
              Coalesce(Job_Usage_Last_Year, 0) <> Coalesce(StatsQ.JobCountLastYear, 0)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        INSERT INTO #Tmp_Update_Stats( Task, Runtime_Seconds )
        SELECT 'Update job counts in T_Param_Files',
               DateDiff(Millisecond, @startTime, GetDate()) / 1000.0

        ------------------------------------------------
        -- Update Usage Counts for Settings Files
        ------------------------------------------------
        --
        Set @startTime = GetDate()

        UPDATE T_Settings_Files
        SET Job_Usage_Count = Coalesce(StatsQ.JobCount, 0),
            Job_Usage_Last_Year = Coalesce(StatsQ.JobCountLastYear, 0)        -- Usage over the last 12 months
        FROM T_Settings_Files SF
             LEFT OUTER JOIN ( SELECT AJ.AJ_settingsFileName AS Settings_File_Name,
                                      AnTool.AJT_toolName,
                                      COUNT(*) AS JobCount,
                                      SUM(CASE
                                              WHEN AJ_Created >= @thresholdOneYear THEN 1
                                              ELSE 0
                                          END) AS JobCountLastYear
                               FROM T_Analysis_Job AJ
                                    INNER JOIN T_Analysis_Tool AnTool
                                      ON AJ.AJ_analysisToolID = AnTool.AJT_toolID
                               GROUP BY AJ.AJ_settingsFileName, AnTool.AJT_toolName
                              ) StatsQ
               ON SF.Analysis_Tool = StatsQ.AJT_toolName AND
                  SF.File_Name = StatsQ.Settings_File_Name
        WHERE Coalesce(Job_Usage_Count, 0) <> Coalesce(StatsQ.JobCount, 0) OR
              Coalesce(Job_Usage_Last_Year, 0) <> Coalesce(StatsQ.JobCountLastYear, 0)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        INSERT INTO #Tmp_Update_Stats( Task, Runtime_Seconds )
        SELECT 'Update job counts in T_Settings_Files',
               DateDiff(Millisecond, @startTime, GetDate()) / 1000.0

        ------------------------------------------------
        -- Update Usage Counts for LC Cart Configuration items
        ------------------------------------------------
        --
        Set @startTime = GetDate()

        UPDATE T_LC_Cart_Configuration
        SET Dataset_Usage_Count = Coalesce(StatsQ.DatasetCount, 0),
            Dataset_Usage_Last_Year = Coalesce(StatsQ.DatasetCountLastYear, 0)        -- Usage over the last 12 months
        FROM T_LC_Cart_Configuration Target
             LEFT OUTER JOIN ( SELECT Cart_Config_ID,
                                      COUNT(*) AS DatasetCount,
                                      SUM(CASE
                                              WHEN DS_Created >= @thresholdOneYear THEN 1
                                              ELSE 0
                                          END) AS DatasetCountLastYear
                               FROM T_Dataset
                               WHERE NOT Cart_Config_ID IS NULL
                               GROUP BY Cart_Config_ID
                              ) StatsQ
               ON Target.Cart_Config_ID = StatsQ.Cart_Config_ID
        WHERE Coalesce(Dataset_Usage_Count, 0) <> Coalesce(StatsQ.DatasetCount, 0) OR
              Coalesce(Dataset_Usage_Last_Year, 0) <> Coalesce(StatsQ.DatasetCountLastYear, 0)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        INSERT INTO #Tmp_Update_Stats( Task, Runtime_Seconds )
        SELECT 'Update dataset counts in T_LC_Cart_Configuration',
               DateDiff(Millisecond, @startTime, GetDate()) / 1000.0

        ------------------------------------------------
        -- Update Usage Counts for Instrument Groups
        ------------------------------------------------
        --
        Set @startTime = GetDate()

        UPDATE T_Instrument_Group_Allowed_DS_Type
        SET Dataset_Usage_Count = Coalesce(StatsQ.DatasetCount, 0),
            Dataset_Usage_Last_Year = Coalesce(StatsQ.DatasetCountLastYear, 0)        -- Usage over the last 12 months
        FROM T_Instrument_Group_Allowed_DS_Type Target
             LEFT OUTER JOIN ( SELECT InstName.IN_Group As Instrument_Group,
                                       DTN.DST_name As Dataset_Type,
                                       COUNT(*) AS DatasetCount,
                                       SUM(CASE
                                               WHEN DS_Created >= @thresholdOneYear THEN 1
                                               ELSE 0
                                           END) AS DatasetCountLastYear
                                FROM T_Dataset DS
                                     INNER JOIN T_Instrument_Name InstName
                                       ON DS.DS_instrument_name_ID = InstName.Instrument_ID
                                     INNER JOIN T_DatasetTypeName DTN
                                       ON DS.DS_type_ID = DTN.DST_Type_ID
                                GROUP BY InstName.IN_Group, DTN.DST_name
                              ) StatsQ
               ON Target.IN_Group = StatsQ.Instrument_Group And
                  Target.Dataset_Type = StatsQ.Dataset_Type
        WHERE Coalesce(Dataset_Usage_Count, 0) <> Coalesce(StatsQ.DatasetCount, 0) OR
              Coalesce(Dataset_Usage_Last_Year, 0) <> Coalesce(StatsQ.DatasetCountLastYear, 0)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        INSERT INTO #Tmp_Update_Stats( Task, Runtime_Seconds )
        SELECT 'Update dataset counts in T_Instrument_Group_Allowed_DS_Type',
               DateDiff(Millisecond, @startTime, GetDate()) / 1000.0



        ------------------------------------------------
        -- Update Usage Counts for Instruments, by dataset type
        ------------------------------------------------
        --
        Set @startTime = GetDate()

        -- Add missing rows to T_Cached_Instrument_Dataset_Type_Usage
        --
        INSERT INTO T_Cached_Instrument_Dataset_Type_Usage( Instrument_ID, Dataset_Type )
        SELECT Distinct InstName.Instrument_ID,
               GT.Dataset_Type AS Dataset_Type
        FROM T_Instrument_Name InstName
             INNER JOIN T_Instrument_Group_Allowed_DS_Type GT
               ON GT.IN_Group = InstName.IN_Group
             LEFT OUTER JOIN T_Cached_Instrument_Dataset_Type_Usage CachedUsage
               ON InstName.Instrument_ID = CachedUsage.Instrument_ID AND
                  GT.Dataset_Type = CachedUsage.Dataset_Type
        WHERE CachedUsage.Instrument_ID IS NULL
        ORDER BY Instrument_ID, Dataset_Type
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        -- Remove extra rows from T_Cached_Instrument_Dataset_Type_Usage
        --
        DELETE T_Cached_Instrument_Dataset_Type_Usage
        WHERE Entry_ID IN ( SELECT CachedData.Entry_ID
                            FROM T_Instrument_Group_Allowed_DS_Type AS GT
                                 INNER JOIN T_Instrument_Name AS InstName
                                   ON GT.IN_Group = InstName.IN_Group
                                 RIGHT OUTER JOIN T_Cached_Instrument_Dataset_Type_Usage AS CachedData
                                   ON GT.Dataset_Type = CachedData.Dataset_Type AND
                                      InstName.Instrument_ID = CachedData.Instrument_ID
                            WHERE GT.IN_Group IS NULL )
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        -- Update stats in T_Cached_Instrument_Dataset_Type_Usage
        --
        Update T_Cached_Instrument_Dataset_Type_Usage
        SET Dataset_Usage_Count = Coalesce(StatsQ.DatasetCount, 0),
            Dataset_Usage_Last_Year = Coalesce(StatsQ.DatasetCountLastYear, 0)
        FROM T_Cached_Instrument_Dataset_Type_Usage Target
             LEFT OUTER JOIN ( SELECT InstName.Instrument_ID,
                                      DTN.DST_name As Dataset_Type,
                                      COUNT(*) AS DatasetCount,
                                      SUM(CASE
                                              WHEN DS_Created >= @thresholdOneYear THEN 1
                                              ELSE 0
                                          END) AS DatasetCountLastYear
                                FROM T_Dataset DS
                                     INNER JOIN T_Instrument_Name InstName
                                       ON DS.DS_instrument_name_ID = InstName.Instrument_ID
                                     INNER JOIN T_DatasetTypeName DTN
                                       ON DS.DS_type_ID = DTN.DST_Type_ID
                                GROUP BY InstName.Instrument_ID, DTN.DST_name
                              ) StatsQ
               ON Target.Instrument_ID = StatsQ.Instrument_ID And
                  Target.Dataset_Type = StatsQ.Dataset_Type
        WHERE Coalesce(Dataset_Usage_Count, 0) <> Coalesce(StatsQ.DatasetCount, 0) OR
              Coalesce(Dataset_Usage_Last_Year, 0) <> Coalesce(StatsQ.DatasetCountLastYear, 0)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        INSERT INTO #Tmp_Update_Stats( Task, Runtime_Seconds )
        SELECT 'Update dataset counts in T_Cached_Instrument_Dataset_Type_Usage',
               DateDiff(Millisecond, @startTime, GetDate()) / 1000.0

        ------------------------------------------------
        -- Update Usage Counts for Protein Collections
        ------------------------------------------------
        --
        Set @startTime = GetDate()

        Exec UpdateProteinCollectionUsage @message output

        INSERT INTO #Tmp_Update_Stats( Task, Runtime_Seconds )
        SELECT 'Update usage counts for protein collections',
               DateDiff(Millisecond, @startTime, GetDate()) / 1000.0
    End -- </a1>

    If @updateGeneralStatistics <> 0
    Begin -- <a2>
        ------------------------------------------------
        -- Make sure T_General_Statistics contains the required categories and labels
        ------------------------------------------------

        Set @startTime = GetDate()

        CREATE TABLE #TmpStatEntries (
            Category varchar(128) NOT NULL,
            Label varchar(128) NOT NULL,
            Sql varchar(1024) NOT NULL,
            UseDecimal tinyint NOT NULL Default 0,
            UniqueID int IDENTITY(1,1)
        )

        INSERT INTO #TmpStatEntries VALUES ('Job_Count', 'All',          'SELECT @Total = COUNT(*) FROM T_Analysis_Job', 0)
        INSERT INTO #TmpStatEntries VALUES ('Job_Count', 'Last 7 days',  'SELECT @Total = COUNT(*) FROM T_Analysis_Job WHERE AJ_created > DATEADD(day, -7, GetDate())', 0)
        INSERT INTO #TmpStatEntries VALUES ('Job_Count', 'Last 30 days', 'SELECT @Total = COUNT(*) FROM T_Analysis_Job WHERE AJ_created > DATEADD(DAY, -30, GetDate())', 0)
        INSERT INTO #TmpStatEntries VALUES ('Job_Count', 'New',          'SELECT @Total = COUNT(*) FROM T_Analysis_Job WHERE AJ_StateID = 1', 0)

        INSERT INTO #TmpStatEntries VALUES ('Campaign_Count', 'All',          'SELECT @Total = COUNT(*) FROM T_Campaign', 0)
        INSERT INTO #TmpStatEntries VALUES ('Campaign_Count', 'Last 7 days',  'SELECT @Total = COUNT(*) FROM T_Campaign WHERE CM_created > DATEADD(day, -7, GetDate())', 0)
        INSERT INTO #TmpStatEntries VALUES ('Campaign_Count', 'Last 30 days', 'SELECT @Total = COUNT(*) FROM T_Campaign WHERE CM_created > DATEADD(day, -30, GetDate())', 0)

        INSERT INTO #TmpStatEntries VALUES ('CellCulture_Count', 'All',          'SELECT @Total = COUNT(*) FROM T_Cell_Culture', 0)
        INSERT INTO #TmpStatEntries VALUES ('CellCulture_Count', 'Last 7 days',  'SELECT @Total = COUNT(*) FROM T_Cell_Culture WHERE CC_Created > DATEADD(day, -7, GetDate())', 0)
        INSERT INTO #TmpStatEntries VALUES ('CellCulture_Count', 'Last 30 days', 'SELECT @Total = COUNT(*) FROM T_Cell_Culture WHERE CC_Created > DATEADD(day, -30, GetDate())', 0)

        INSERT INTO #TmpStatEntries VALUES ('Dataset_Count', 'All',          'SELECT @Total = COUNT(*) FROM T_Dataset', 0)
        INSERT INTO #TmpStatEntries VALUES ('Dataset_Count', 'Last 7 days',  'SELECT @Total = COUNT(*) FROM T_Dataset WHERE DS_created > DATEADD(day, -7, GetDate())', 0)
        INSERT INTO #TmpStatEntries VALUES ('Dataset_Count', 'Last 30 days', 'SELECT @Total = COUNT(*) FROM T_Dataset WHERE DS_created > DATEADD(day, -30, GetDate())', 0)

        INSERT INTO #TmpStatEntries VALUES ('Experiment_Count', 'All',          'SELECT @Total = COUNT(*) FROM T_Experiments', 0)
        INSERT INTO #TmpStatEntries VALUES ('Experiment_Count', 'Last 7 days',  'SELECT @Total = COUNT(*) FROM T_Experiments WHERE EX_created > DATEADD(day, -7, GetDate())', 0)
        INSERT INTO #TmpStatEntries VALUES ('Experiment_Count', 'Last 30 days', 'SELECT @Total = COUNT(*) FROM T_Experiments WHERE EX_created > DATEADD(day, -30, GetDate())', 0)

        INSERT INTO #TmpStatEntries VALUES ('Organism_Count', 'All', 'SELECT @Total = COUNT(*) FROM T_Organisms', 0)
        INSERT INTO #TmpStatEntries VALUES ('Organism_Count', 'Last 7 days',  'SELECT @Total = COUNT(*) FROM T_Organisms WHERE OG_Created > DATEADD(day, -7, GetDate())', 0)
        INSERT INTO #TmpStatEntries VALUES ('Organism_Count', 'Last 30 days', 'SELECT @Total = COUNT(*) FROM T_Organisms WHERE OG_Created > DATEADD(day, -30, GetDate())', 0)

        INSERT INTO #TmpStatEntries VALUES ('RawDataTB', 'All',          'SELECT @TotalDec = Round(SUM(Coalesce(File_Size_Bytes,0)) / 1024.0 / 1024.0 / 1024.0 / 1024.0, 2) FROM T_Dataset', 1)
        INSERT INTO #TmpStatEntries VALUES ('RawDataTB', 'Last 7 days',  'SELECT @TotalDec = Round(SUM(Coalesce(File_Size_Bytes,0)) / 1024.0 / 1024.0 / 1024.0 / 1024.0, 2) FROM T_Dataset WHERE DS_Created > DATEADD(day, -7, GetDate())', 1)
        INSERT INTO #TmpStatEntries VALUES ('RawDataTB', 'Last 30 days', 'SELECT @TotalDec = Round(SUM(Coalesce(File_Size_Bytes,0)) / 1024.0 / 1024.0 / 1024.0 / 1024.0, 2) FROM T_Dataset WHERE DS_Created > DATEADD(day, -30, GetDate())', 1)

        -- Initialize @SqlParams
        Set @SqlParams = '@Total int output'
        Set @SqlParamsDec = '@TotalDec decimal(18, 3) output'

        ------------------------------------------------
        -- Use the queries in #TmpStatEntries to update T_General_Statistics
        ------------------------------------------------

        Set @UniqueID = 0

        Set @Continue = 1
        While @Continue = 1
        Begin -- <b>
            SELECT TOP 1 @Category = Category,
                         @Label = Label,
                         @Sql = Sql,
                         @UseDecimal = UseDecimal,
                         @UniqueID = UniqueID
            FROM #TmpStatEntries
            WHERE UniqueID > @UniqueID
            ORDER BY UniqueID
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            If @myRowCount = 0
                Set @Continue = 0
            Else -- <c>
            Begin
                If @previewSql <> 0
                    Print @Sql
                Else
                Begin -- <d>

                    ------------------------------------------------
                    -- Run the query in @Sql; store the value for @Total in T_General_Statistics
                    ------------------------------------------------

                    If @UseDecimal = 0
                    Begin
                        Set @Total = 0
                        exec sp_executesql @Sql, @SqlParams, @Total = @Total Output
                        Set @Value = Convert(varchar(12), Coalesce(@Total, 0))
                    End
                    Else
                    Begin
                        Set @TotalDec = 0
                        exec sp_executesql @Sql, @SqlParamsDec, @TotalDec = @TotalDec Output
                        Set @Value = Convert(varchar(12), Coalesce(@TotalDec, 0))
                    End

                    IF Exists ( SELECT * FROM T_General_Statistics WHERE Category = @Category AND Label = @Label )
                    Begin
                        UPDATE T_General_Statistics
                        SET Value = @Value, Last_Affected = GetDate()
                        WHERE Category = @Category AND
                              Label = @Label AND
                              Coalesce(Value, '0') <> Coalesce(@Value, '0')
                    End
                    Else
                    Begin
                        INSERT INTO T_General_Statistics( Category, Label, Value, Last_Affected)
                        VALUES(@Category, @Label, @Value, GetDate())
                    End
                End -- </d>

            End -- </c>
        End -- </b>

        INSERT INTO #Tmp_Update_Stats( Task, Runtime_Seconds )
        SELECT 'Update values in T_General_Statistics',
               DateDiff(Millisecond, @startTime, GetDate()) / 1000.0
    End -- </a2>

    If @updateJobRequestStatistics <> 0
    Begin -- <a3>
        Set @startTime = GetDate()

        UPDATE T_Analysis_Job_Request
        SET AJR_jobCount = StatQ.JobCount
        FROM T_Analysis_Job_Request AJR
             INNER JOIN ( SELECT AJR.AJR_requestID,
                                 SUM(CASE
                                         WHEN AJ.AJ_jobID IS NULL THEN 0
                                         ELSE 1
                                     END) AS JobCount
                          FROM T_Analysis_Job_Request AJR
                               INNER JOIN T_Users U
                                 ON AJR.AJR_requestor = U.ID
                               INNER JOIN T_Analysis_Job_Request_State AJRS
                                 ON AJR.AJR_state = AJRS.ID
                               INNER JOIN T_Organisms Org
                                 ON AJR.AJR_organism_ID = Org.Organism_ID
                               LEFT OUTER JOIN T_Analysis_Job AJ
                                 ON AJR.AJR_requestID = AJ.AJ_requestID
                          GROUP BY AJR.AJR_requestID
                         ) StatQ
               ON AJR.AJR_requestID = StatQ.AJR_requestID AND
                  Coalesce(AJR.AJR_jobCount, - 1) <> StatQ.JobCount
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        INSERT INTO #Tmp_Update_Stats( Task, Runtime_Seconds )
        SELECT 'Update job counts in T_Analysis_Job_Request',
               DateDiff(Millisecond, @startTime, GetDate()) / 1000.0
    End -- </a3>

    If @showRuntimeStats > 0
    Begin
        SELECT *
        FROM #Tmp_Update_Stats
        UNION
        SELECT 15 AS Entry_ID,
               'Total runtime' AS Task,
               Sum(Runtime_Seconds) AS Runtime_Seconds
        FROM #Tmp_Update_Stats
        ORDER BY Entry_ID
    End

Done:
    return @myError


GO
GRANT EXECUTE ON [dbo].[UpdateCachedStatistics] TO [D3L243] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateCachedStatistics] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateCachedStatistics] TO [Limited_Table_Write] AS [dbo]
GO
