/****** Object:  StoredProcedure [dbo].[update_eus_users_from_eus_imports] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[update_eus_users_from_eus_imports]
/****************************************************
**
**  Desc:
**      Updates associated EUS user associations for
**      proposals that are currently active in DMS
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**  Date:   03/01/2006 grk - Initial version
**          03/24/2011 mem - Updated to use V_EUS_Import_Proposal_Participants
**          03/25/2011 mem - Updated to remove entries from T_EUS_Proposal_Users if the row is no longer in V_EUS_Import_Proposal_Participants yet the proposal is still active
**          04/01/2011 mem - No longer removing entries from T_EUS_Proposal_Users; now changing to state 5="No longer associated with proposal"
**                         - Added support for state 4="Permanently associated with proposal"
**          09/02/2011 mem - Now calling post_usage_log_entry
**          03/19/2012 mem - Now populating T_EUS_Users.HID
**          02/23/2016 mem - Add set XACT_ABORT on
**          05/12/2021 mem - Use new NEXUS-based views
**                         - Add option to update EUS Users for Inactive proposals
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          03/01/2024 mem - Only change state_id to 3 in T_EUS_Proposal_Users if state_id is not 2, 3, 4, or 5 (previously not 2 or 4)
**                         - This change was made to avoid state_id changing from 5 to 3, then from 3 back to 5 every time this procedure is called
**          07/07/2024 mem - Use get_eus_users_proposal_list() to cache EUS proposals associated with each user
**
*****************************************************/
(
    @updateUsersOnInactiveProposals tinyint = 0,
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

    Set @updateUsersOnInactiveProposals = IsNull(@updateUsersOnInactiveProposals, 0)

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

        Set @currentLocation = 'Update T_EUS_Users'
        Print @currentLocation

        ---------------------------------------------------
        -- Use a MERGE Statement to synchronize
        -- T_EUS_User with V_NEXUS_Import_Proposal_Participants
        ---------------------------------------------------

        MERGE T_EUS_Users AS target
        USING
            (
               SELECT DISTINCT Source.[user_id] as Person_ID,
                               Source.name_fm,
                               CASE WHEN hanford_id IS NULL
                                    THEN NULL
                                    ELSE 'H' + hanford_id
                                    END AS HID,
                               CASE WHEN hanford_id IS NULL
                                    THEN 2        -- Offsite
                                    ELSE 1        -- Onsite
                                    END as Site_Status,
                               Source.first_name,
                               Source.last_name
               FROM dbo.V_NEXUS_Import_Proposal_Participants Source
                    INNER JOIN ( SELECT PROPOSAL_ID
                                 FROM T_EUS_Proposals
                                 WHERE State_ID IN (1,2) Or
                                       @updateUsersOnInactiveProposals > 0 And State_ID <> 4   -- State for is "No Interest"
                                ) DmsEUSProposals
                      ON Source.project_id = DmsEUSProposals.PROPOSAL_ID
            ) AS Source (Person_ID, name_fm, HID, Site_Status, first_name, last_name)
        ON (target.Person_ID = Source.Person_ID)
        WHEN Matched AND
                    (   target.NAME_FM <> Source.name_fm OR
                        (IsNull(target.HID, '') <> Source.HID AND NOT Source.HID is null) OR
                        target.Site_Status <> Source.Site_Status OR
                        (IsNull(target.First_Name, '') <> Source.first_name AND NOT Source.first_name is null) OR
                        (IsNull(target.Last_Name, '') <> Source.last_name AND NOT Source.last_name is null)
                    )
            THEN UPDATE
                Set NAME_FM = Source.name_fm,
                    HID = IsNull(Source.HID, target.HID),
                    Site_Status = Source.Site_Status,
                    First_Name = Source.first_name,
                    Last_Name = Source.last_name,
                    Last_Affected = GetDate()
        WHEN NOT MATCHED THEN
            INSERT (Person_ID, NAME_FM, HID, Site_Status, First_Name, Last_Name, Last_Affected)
            VALUES (Source.Person_ID, Source.name_fm, Source.HID, Source.Site_Status, Source.first_name, Source.last_name, GetDate())
        -- Note: don't delete data from T_EUS_Users
        -- WHEN NOT MATCHED BY SOURCE THEN
        --  could DELETE
        OUTPUT $action INTO #Tmp_UpdateSummary;

        if @myError <> 0
        begin
            Set @message = 'Error merging V_NEXUS_Import_Proposal_Participants with T_EUS_Users (ErrorID = ' + Convert(varchar(12), @myError) + ')'
            execute post_log_entry 'Error', @message, 'update_eus_users_from_eus_imports'
            goto Done
        end

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
            Set @message = 'Updated T_EUS_Users: ' + Convert(varchar(12), @mergeInsertCount) + ' added; ' + Convert(varchar(12), @mergeUpdateCount) + ' updated'

            If @mergeDeleteCount > 0
                Set @message = @message + '; ' + Convert(varchar(12), @mergeDeleteCount) + ' deleted'

            Exec post_log_entry 'Normal', @message, 'update_eus_users_from_eus_imports'
            Set @message = ''
        End

        Set @currentLocation = 'Update First_Name and Last_Name in T_EUS_Users'

        UPDATE T_EUS_Users
        SET First_Name = Ltrim(SubString(Name_FM, CharIndex(',', Name_FM) + 1, 128))
        WHERE IsNull(First_Name, '') = '' And CharIndex(',', Name_FM) > 1

        UPDATE T_EUS_Users
        SET Last_Name = SubString(Name_FM, 1, CharIndex(',', Name_FM) - 1)
        WHERE IsNull(Last_Name, '') = '' And CharIndex(',', Name_FM) > 1

        Set @currentLocation = 'Update T_EUS_Proposal_Users'
        Print @currentLocation

        ---------------------------------------------------
        -- Use a MERGE Statement to synchronize
        -- T_EUS_User with V_NEXUS_Import_Proposal_Participants
        ---------------------------------------------------

        DELETE FROM #Tmp_UpdateSummary

        MERGE T_EUS_Proposal_Users AS target
        USING
            (
               SELECT DISTINCT Source.project_id AS Proposal_ID,
                               Source.[user_id] As Person_ID,
                               'Y' AS Of_DMS_Interest
               FROM dbo.V_NEXUS_Import_Proposal_Participants Source
                    INNER JOIN ( SELECT Proposal_ID
                                 FROM T_EUS_Proposals
                                 WHERE State_ID IN (1,2)
                               ) DmsEUSProposals
                      ON Source.project_id = DmsEUSProposals.Proposal_ID
            ) AS Source (Proposal_ID, Person_ID, Of_DMS_Interest)
        ON (target.Proposal_ID = Source.Proposal_ID AND
            target.Person_ID = Source.Person_ID)
        WHEN MATCHED AND IsNull(target.State_ID, 0) NOT IN (1, 4)
            THEN UPDATE
                Set State_ID = 1,
                    Last_Affected = GetDate()
        WHEN NOT MATCHED THEN
            INSERT (Proposal_ID, Person_ID, Of_DMS_Interest, State_ID, Last_Affected)
            VALUES (Source.Proposal_ID, Source.PERSON_ID, Source.Of_DMS_Interest, 1, GetDate())
        WHEN NOT MATCHED BY SOURCE AND IsNull(State_ID, 0) NOT IN (2, 3, 4, 5)
            -- User/proposal mapping is defined in T_EUS_Proposal_Users but not in V_NEXUS_Import_Proposal_Participants
            -- Flag entry to indicate we need to possibly update the state for this row to 5 (checked later in the procedure)
            THEN UPDATE SET State_ID = 3, Last_Affected = GetDate()
        OUTPUT $action INTO #Tmp_UpdateSummary;

        if @myError <> 0
        begin
            Set @message = 'Error merging V_NEXUS_Import_Proposal_Participants with T_EUS_Proposal_Users (ErrorID = ' + Convert(varchar(12), @myError) + ')'
            execute post_log_entry 'Error', @message, 'update_eus_users_from_eus_imports'
            goto Done
        end

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

        ---------------------------------------------------
        -- Update rows in T_EUS_Proposal_Users where State_ID is 3=Unknown
        -- but the associated proposal has state of 3=Inactive
        ---------------------------------------------------

        UPDATE T_EUS_Proposal_Users
        SET State_ID = 2
        FROM T_EUS_Proposal_Users
             INNER JOIN T_EUS_Proposals
               ON T_EUS_Proposal_Users.Proposal_ID = T_EUS_Proposals.PROPOSAL_ID
        WHERE T_EUS_Proposal_Users.State_ID = 3 AND
              T_EUS_Proposals.State_ID IN (3,4)
        --
        SELECT @myRowCount = @@rowcount, @myError = @@error

        ---------------------------------------------------
        -- Update rows in T_EUS_Proposal_Users that still have State_ID is 3=Unknown
        -- but the associated proposal has state 2=Active
        ---------------------------------------------------

        UPDATE T_EUS_Proposal_Users
        SET State_ID = 5
        FROM T_EUS_Proposal_Users
             INNER JOIN T_EUS_Proposals
               ON T_EUS_Proposal_Users.Proposal_ID = T_EUS_Proposals.PROPOSAL_ID
        WHERE T_EUS_Proposal_Users.State_ID = 3 AND
              T_EUS_Proposals.State_ID = 2
        --
        SELECT @myRowCount = @@rowcount, @myError = @@error

        If @mergeUpdateCount > 0 OR @mergeInsertCount > 0 OR @mergeDeleteCount > 0
        Begin
            Set @message = 'Updated T_EUS_Proposal_Users: ' + Convert(varchar(12), @mergeInsertCount) + ' added; ' + Convert(varchar(12), @mergeUpdateCount) + ' updated'

            If @mergeDeleteCount > 0
                Set @message = @message + '; ' + Convert(varchar(12), @mergeDeleteCount) + ' deleted'

            Exec post_log_entry 'Normal', @message, 'update_eus_users_from_eus_imports'
            Set @message = ''
        End

        ---------------------------------------------------
        -- Update cached eus_proposals in T_EUS_Users
        ---------------------------------------------------

        Set @currentLocation = 'Update cached EUS proposals in T_EUS_Users'
        Print @currentLocation

        MERGE T_EUS_Users AS t
        USING (SELECT U.person_id,
                      dbo.get_eus_users_proposal_list(U.person_id) AS Proposals
               FROM T_EUS_Users U
              ) AS s
        ON (t.person_id = s.person_id)
        WHEN MATCHED AND (
            ISNULL( NULLIF(t.EUS_Proposals, s.Proposals),
            NULLIF(s.Proposals, t.EUS_Proposals)) IS NOT NULL
            )
        THEN UPDATE SET
            EUS_Proposals = s.proposals;

    End Try
    Begin Catch
        -- Error caught; log the error then abort processing
        Set @callingProcName = IsNull(ERROR_PROCEDURE(), 'update_eus_users_from_eus_imports')
        exec local_error_handler  @callingProcName, @currentLocation, @LogError = 1,
                                @ErrorNum = @myError output, @message = @message output
        Goto Done
    End Catch

Done:
    ---------------------------------------------------
    -- Log SP usage
    ---------------------------------------------------

    Declare @usageMessage varchar(512) = ''
    Exec post_usage_log_entry 'update_eus_users_from_eus_imports', @usageMessage

    Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[update_eus_users_from_eus_imports] TO [DDL_Viewer] AS [dbo]
GO
GRANT ALTER ON [dbo].[update_eus_users_from_eus_imports] TO [DMS_EUS_Admin] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[update_eus_users_from_eus_imports] TO [DMS_EUS_Admin] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[update_eus_users_from_eus_imports] TO [DMS_EUS_Admin] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[update_eus_users_from_eus_imports] TO [Limited_Table_Write] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[update_eus_users_from_eus_imports] TO [PNL\D3M578] AS [dbo]
GO
