/****** Object:  StoredProcedure [dbo].[refresh_cached_ptdbs] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[refresh_cached_ptdbs]
/****************************************************
**
**  Desc:   Updates the data in T_MTS_PT_DBs_Cached using MTS
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**  Date:   02/05/2010 mem - Initial Version
**          02/23/2016 mem - Add set XACT_ABORT on
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @message varchar(255) = '' output
)
AS
    Set XACT_ABORT, nocount on

    Declare @myRowCount int
    Declare @myError int
    Set @myRowCount = 0
    Set @myError = 0

    set @message = ''

    Declare @MergeUpdateCount int
    Declare @MergeInsertCount int
    Declare @MergeDeleteCount int

    Set @MergeUpdateCount = 0
    Set @MergeInsertCount = 0
    Set @MergeDeleteCount = 0

    ---------------------------------------------------
    -- Create the temporary table that will be used to
    -- track the number of inserts, updates, and deletes
    -- performed by the MERGE statement
    ---------------------------------------------------

    CREATE TABLE #Tmp_UpdateSummary (
        UpdateAction varchar(32)
    )

    CREATE CLUSTERED INDEX #IX_Tmp_UpdateSummary ON #Tmp_UpdateSummary (UpdateAction)


    Declare @FullRefreshPerformed tinyint

    declare @CallingProcName varchar(128)
    declare @CurrentLocation varchar(128)
    Set @CurrentLocation = 'Start'

    Begin Try
        Set @CurrentLocation = 'Validate the inputs'

        -- Validate the inputs
        Set @FullRefreshPerformed = 1

        Set @CurrentLocation = 'Update T_MTS_Cached_Data_Status'
        --
        Exec update_mts_cached_data_status 'T_MTS_PT_DBs_Cached', @IncrementRefreshCount = 0, @FullRefreshPerformed = @FullRefreshPerformed, @LastRefreshMinimumID = 0




        -- Use a MERGE Statement (introduced in Sql Server 2008) to synchronize T_MTS_PT_DBs_Cached with S_MTS_PT_DBs

        MERGE T_MTS_PT_DBs_Cached AS target
        USING
            (SELECT Server_Name, Peptide_DB_ID, Peptide_DB_Name,
                    State_ID, State, [Description],
                    Organism,
                    Last_Affected
             FROM   S_MTS_PT_DBs AS MTSDBInfo
            ) AS Source (   Server_Name, Peptide_DB_ID, Peptide_DB_Name,
                            State_ID, State, [Description],
                            Organism,
                            Last_Affected)
        ON (target.Peptide_DB_ID = source.Peptide_DB_ID)
        WHEN Matched AND
                    (   target.Server_Name <> source.Server_Name OR
                        target.Peptide_DB_Name <> source.Peptide_DB_Name OR
                        target.State_ID <> source.State_ID OR
                        target.State <> source.State OR
                        IsNull(target.[Description],'') <> IsNull(source.[Description],'') OR
                        IsNull(target.Organism,'') <> IsNull(source.Organism,'') OR
                        IsNull(target.Last_Affected ,'')<> IsNull(source.Last_Affected,'')
                    )
            THEN UPDATE
                Set Server_Name = source.Server_Name,
                    Peptide_DB_Name = source.Peptide_DB_Name,
                    State_ID = source.State_ID,
                    State = source.State,
                    [Description] = source.[Description],
                    Organism = source.Organism,
                    Last_Affected = source.Last_Affected
        WHEN Not Matched THEN
            INSERT (Server_Name, Peptide_DB_ID, Peptide_DB_Name,
                    State_ID, State, [Description],
                    Organism,
                    Last_Affected
                    )
            VALUES (source.Server_Name, source.Peptide_DB_ID, source.Peptide_DB_Name,
                    source.State_ID, source.State, source.[Description],
                    source.Organism,
                    source.Last_Affected)
        WHEN NOT MATCHED BY SOURCE THEN
            DELETE
        OUTPUT $action INTO #Tmp_UpdateSummary
        ;

        if @myError <> 0
        begin
            set @message = 'Error merging S_MTS_PT_DBs with T_MTS_PT_DBs_Cached (ErrorID = ' + Convert(varchar(12), @myError) + ')'
            execute post_log_entry 'Error', @message, 'refresh_cached_ptdbs'
            goto Done
        end


        set @MergeUpdateCount = 0
        set @MergeInsertCount = 0
        set @MergeDeleteCount = 0

        SELECT @MergeInsertCount = COUNT(*)
        FROM #Tmp_UpdateSummary
        WHERE UpdateAction = 'INSERT'

        SELECT @MergeUpdateCount = COUNT(*)
        FROM #Tmp_UpdateSummary
        WHERE UpdateAction = 'UPDATE'

        SELECT @MergeDeleteCount = COUNT(*)
        FROM #Tmp_UpdateSummary
        WHERE UpdateAction = 'DELETE'


        Set @CurrentLocation = 'Update stats in T_MTS_Cached_Data_Status'
        --
        --
        Exec update_mts_cached_data_status 'T_MTS_PT_DBs_Cached',
                                            @IncrementRefreshCount = 1,
                                            @InsertCountNew = @MergeInsertCount,
                                            @UpdateCountNew = @MergeUpdateCount,
                                            @DeleteCountNew = @MergeDeleteCount,
                                            @FullRefreshPerformed = @FullRefreshPerformed,
                                            @LastRefreshMinimumID = 0

    End Try
    Begin Catch
        -- Error caught; log the error then abort processing
        Set @CallingProcName = IsNull(ERROR_PROCEDURE(), 'RefreshCachedMTSAnalysisJobInfo')
        exec local_error_handler  @CallingProcName, @CurrentLocation, @LogError = 1,
                                @ErrorNum = @myError output, @message = @message output
        Goto Done
    End Catch

Done:
    Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[refresh_cached_ptdbs] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[refresh_cached_ptdbs] TO [Limited_Table_Write] AS [dbo]
GO
