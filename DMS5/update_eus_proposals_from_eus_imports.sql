/****** Object:  StoredProcedure [dbo].[UpdateEUSProposalsFromEUSImports] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[UpdateEUSProposalsFromEUSImports]
/****************************************************
**
**  Desc:   Updates EUS proposals in T_EUS_Proposals
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**  Auth:   mem
**  Date:   03/24/2011 mem - Initial version
**          03/25/2011 mem - Now automatically setting proposal state_id to 3=Inactive
**          05/02/2011 mem - Now changing proposal state_ID to 2=Active if the proposal is present in V_EUS_Import_Proposals but the proposal's state in T_EUS_Proposals is not 2=Active or 4=No Interest
**          09/02/2011 mem - Now calling PostUsageLogEntry
**          01/27/2012 mem - Added support for state 5=Permanently Active
**          03/20/2013 mem - Changed from Call_Type to Proposal_Type
**          02/23/2016 mem - Add set XACT_ABORT on
**          10/05/2016 mem - Update logic to allow for V_EUS_Import_Proposals to include inactive proposals
**          11/09/2018 mem - Mark proposals as "Active" if their start date is in the future
**          05/12/2021 mem - Use new NEXUS-based views
**          05/14/2021 mem - Handle null values for actual_start_date
**          05/24/2021 mem - Add new proposal types to T_EUS_Proposal_Type
**          05/24/2022 mem - Avoid inserting duplicate proposals into T_EUS_Proposals by filtering on IdRank
**
*****************************************************/
(
    @message varchar(512) = '' output
)
AS
    Set XACT_ABORT, nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Declare @mergeUpdateCount int = 0
    Declare @mergeInsertCount int = 0
    Declare @mergeDeleteCount int = 0

    Declare @callingProcName varchar(128)
    Declare @currentLocation varchar(128) = 'Start'

    Begin Try

        ---------------------------------------------------
        -- Create the temporary table that will be used to
        -- track the number of inserts, updates, and deletes
        -- performed by the MERGE statement
        ---------------------------------------------------

        CREATE TABLE #Tmp_UpdateSummary (
            UpdateAction varchar(32)
        )

        CREATE CLUSTERED INDEX #IX_Tmp_UpdateSummary ON #Tmp_UpdateSummary (UpdateAction)

        Set @currentLocation = 'Update T_EUS_Proposals'

        ---------------------------------------------------
        -- Use a MERGE Statement to synchronize
        -- T_EUS_Proposals with V_NEXUS_Import_Proposals
        ---------------------------------------------------

        MERGE T_EUS_Proposals AS target
        USING
            (
               SELECT project_id as Proposal_ID,
                      title,
                      proposal_type_display AS Proposal_Type,
                      actual_start_date AS Proposal_Start_Date,
                      actual_end_date AS Proposal_End_Date,
                      CASE WHEN actual_start_date > GetDate() THEN 1     -- Proposal start date is later than today; mark it active anyway
                           WHEN GetDate() BETWEEN IsNull(actual_start_date, GetDate()) AND DateAdd(Day, 1, actual_end_date) THEN 1
                           ELSE 0
                      END AS Active
               FROM dbo.V_NEXUS_Import_Proposals
               WHERE IdRank = 1
            ) AS Source ( Proposal_ID, Title, Proposal_Type, Proposal_Start_Date, Proposal_End_Date, Active)
        ON (target.Proposal_ID = source.Proposal_ID)
        WHEN Matched AND
                    ( target.Title <> convert(varchar(2048), source.Title) OR
                      target.Proposal_Type <> source.Proposal_Type OR
                      IsNull(target.Proposal_Start_Date, '1/1/2000') <> source.Proposal_Start_Date OR
                      IsNull(target.Proposal_End_Date, '1/1/2000') <> source.Proposal_End_Date OR
                      source.Active = 1 And target.State_ID NOT IN (2, 4) OR
                      source.Active = 0 And target.State_ID IN (1, 2)
                    )
            THEN UPDATE
                Set Title = source.Title,
                    Proposal_Type = source.Proposal_Type,
                    Proposal_Start_Date = source.Proposal_Start_Date,
                    Proposal_End_Date = source.Proposal_End_Date,
                    State_ID = CASE WHEN State_ID IN (4, 5)
                                    THEN target.State_ID
                                    ELSE CASE WHEN Active = 1 THEN 2 ELSE 3 END
                               END,
                    Last_Affected = GetDate()
        WHEN NOT MATCHED THEN
            INSERT (Proposal_ID, Title, State_ID, Import_Date,
                    Proposal_Type, Proposal_Start_Date, Proposal_End_Date, Last_Affected)
            VALUES (source.Proposal_ID, source.Title, 2, GetDate(),
                    source.Proposal_Type, source.Proposal_Start_Date, source.Proposal_End_Date, GetDate())
        WHEN NOT MATCHED BY SOURCE AND target.State_ID IN (1, 2)
            THEN UPDATE
            SET State_ID = 3                -- Auto-change state to Inactive
        OUTPUT $action INTO #Tmp_UpdateSummary;

        If @myError <> 0
        Begin
            Set @message = 'Error merging V_EUS_Import_Proposals with T_EUS_Proposals (ErrorID = ' + Convert(varchar(12), @myError) + ')'
            execute PostLogEntry 'Error', @message, 'UpdateEUSProposalsFromEUSImports'
            goto Done
        End

        Set @mergeUpdateCount = 0
        Set @mergeInsertCount = 0
        Set @mergeDeleteCount = 0

        SELECT @mergeInsertCount = COUNT(*)
        FROM #Tmp_UpdateSummary
        WHERE UpdateAction = 'INSERT'

        SELECT @mergeUpdateCount = COUNT(*)
        FROM #Tmp_UpdateSummary
        WHERE UpdateAction = 'UPDATE'

        SELECT @mergeDeleteCount = COUNT(*)
        FROM #Tmp_UpdateSummary
        WHERE UpdateAction = 'DELETE'

        If @mergeUpdateCount > 0 OR @mergeInsertCount > 0 OR @mergeDeleteCount > 0
        Begin
            Set @message = 'Updated T_EUS_Proposals: ' + Convert(varchar(12), @mergeInsertCount) + ' added; ' + Convert(varchar(12), @mergeUpdateCount) + ' updated'

            If @mergeDeleteCount > 0
                Set @message = @message + '; ' + Convert(varchar(12), @mergeDeleteCount) + ' deleted'

            Exec PostLogEntry 'Normal', @message, 'UpdateEUSProposalsFromEUSImports'
            Set @message = ''
        End

        ---------------------------------------------------
        -- Add new proposal types to T_EUS_Proposal_Type
        ---------------------------------------------------

        INSERT INTO T_EUS_Proposal_Type( Proposal_Type,
                                         Proposal_Type_Name,
                                         Abbreviation )
        SELECT DISTINCT EUP.Proposal_Type,
                        EUP.Proposal_Type,
                        Replace(EUP.Proposal_Type, ' ', '')
        FROM T_EUS_Proposals EUP
             LEFT OUTER JOIN T_EUS_Proposal_Type EPT
               ON EUP.Proposal_Type = EPT.Proposal_Type
        WHERE NOT EUP.Proposal_Type IS NULL AND
              EPT.Proposal_Type_Name IS NULL
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @myRowCount > 0
        Begin
            Set @message = 'Added ' + Cast(@myRowCount As Varchar(12)) + ' new proposal ' + dbo.CheckPlural(@myRowCount, 'type', 'types') + ' to T_EUS_Proposal_Type'

            Exec PostLogEntry 'Normal', @message, 'UpdateEUSProposalsFromEUSImports'
            Set @message = ''
        End

    End Try
    Begin Catch
        -- Error caught; log the error then abort processing
        Set @callingProcName = IsNull(ERROR_PROCEDURE(), 'UpdateEUSProposalsFromEUSImports')
        exec LocalErrorHandler  @callingProcName, @currentLocation, @LogError = 1,
                                @ErrorNum = @myError output, @message = @message output
        Goto Done
    End Catch

    ---------------------------------------------------
    -- Done
    ---------------------------------------------------

Done:
    ---------------------------------------------------
    -- Log SP usage
    ---------------------------------------------------

    Declare @usageMessage varchar(512) = ''
    Exec PostUsageLogEntry 'UpdateEUSProposalsFromEUSImports', @usageMessage

    Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[UpdateEUSProposalsFromEUSImports] TO [DDL_Viewer] AS [dbo]
GO
