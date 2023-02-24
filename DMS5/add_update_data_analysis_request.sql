/****** Object:  StoredProcedure [dbo].[add_update_data_analysis_request] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[add_update_data_analysis_request]
/****************************************************
**
**  Desc:
**      Adds new or edits existing Data Analysis Request
**
**      The analysis request must be associated with
**      at least one of the following data containers:
**        - One or more requested run batches
**        - Data package
**        - Experiment group
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**  Date:   03/22/2022 mem - Initial version
**          03/26/2022 mem - Replace parameter @batchID with @batchIDs
**                         - Add parameter @comment
**          08/08/2022 mem - Update State_Changed when the state changes
**          02/09/2023 bcg - Update view column name
**          02/13/2023 bcg - Send the correct procedure name to validate_request_users
**                         - Rename parameter to requesterUsername
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @requestName varchar(128),
    @analysisType varchar(16),
    @requesterUsername varchar(32),
    @description varchar(1024),
    @analysisSpecifications varchar(2048),
    @comment varchar(2048),
    @batchIDs varchar(1024) = '',           -- Comma separated list of Requested Run Batch IDs
    @dataPackageID int = null,              -- Data Package ID; can be null
    @experimentGroupID int = null,          -- Experiment Group ID; can be null
    @workPackage varchar(64),
    @requestedPersonnel varchar(256),
    @assignedPersonnel varchar(256),
    @priority varchar(12),
    @reasonForHighPriority varchar(1024),
    @estimatedAnalysisTimeDays int,
    @state varchar(32),                     -- New, On Hold, Analysis in Progress, or Closed
    @stateComment varchar(512),
    @id int output,                         -- Input/output: Data Analysis Request ID
    @mode varchar(24) = 'add',              -- 'add', 'update', or 'previewadd', 'previewupdate'
    @message varchar(1024) output,
    @callingUser varchar(128) = ''
)
AS
    Set XACT_ABORT, nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Set @message = ''

    Declare @msg varchar(512)

    Declare @currentStateID int

    Declare @requestType varchar(16) = 'Default'
    Declare @logErrors tinyint = 0

    Declare @batchDescription varchar(64) = ''

    Set @estimatedAnalysisTimeDays = IsNull(@estimatedAnalysisTimeDays, 1)

    Set @requestedPersonnel = Ltrim(Rtrim(IsNull(@requestedPersonnel, '')))
    Set @assignedPersonnel = Ltrim(Rtrim(IsNull(@assignedPersonnel, 'na')))

    If @assignedPersonnel = ''
        Set @assignedPersonnel = 'na'

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = verify_sp_authorized 'add_update_data_analysis_request', @raiseError = 1
    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;

    Begin Try

    ---------------------------------------------------
    -- Validate input fields
    ---------------------------------------------------
    --
    Set @analysisType = IsNull(@analysisType, '')

    If Len(IsNull(@description, '')) < 1
        RAISERROR ('The description field is required', 11, 116)

    If @state In ('New', 'Closed')
    Begin
        -- Always clear State Comment when the state is new or closed
        Set @stateComment = ''
    End

    Declare @allowUpdateEstimatedAnalysisTime tinyint = 0

    If Exists ( SELECT U.U_PRN
                FROM T_Users U
                     INNER JOIN T_User_Operations_Permissions UOP
                       ON U.ID = UOP.U_ID
                     INNER JOIN T_User_Operations UO
                       ON UOP.Op_ID = UO.ID
                WHERE U.U_Status = 'Active' AND
                      UO.Operation = 'DMS_Data_Analysis_Request' AND
                      U_PRN = @callingUser)
    Begin
          Set @allowUpdateEstimatedAnalysisTime = 1
    End

    ---------------------------------------------------
    -- Validate priority
    ---------------------------------------------------

    If @priority <> 'Normal' AND ISNULL(@reasonForHighPriority, '') = ''
        RAISERROR ('Priority "%s" requires justification reason to be provided', 11, 37, @priority)

    If Not @priority IN ('Normal', 'High')
        RAISERROR ('Priority should be Normal or High', 11, 37)

    ---------------------------------------------------
    -- Validate analysis type
    ---------------------------------------------------
    --
    If NOT Exists (Select * From T_Data_Analysis_Request_Type_Name Where Analysis_Type = @analysisType)
    Begin
        RAISERROR ('Invalid data analysis type: %s', 11, 1, @analysisType)
    End

    ---------------------------------------------------
    -- Resolve Batch IDs, Data Package id, and Experiment Group ID
    -- Require that at least one be valid
    ---------------------------------------------------

    Create Table #Tmp_BatchIDs (
        Batch_ID Int Not Null
    )

    Set @batchIDs = Ltrim(Rtrim(IsNull(@batchIDs, '')))
    Set @dataPackageID = IsNull(@dataPackageID, 0)
    Set @experimentGroupID = IsNull(@experimentGroupID, 0)

    Declare @batchDefined tinyint = 0
    Declare @dataPackageDefined tinyint = 0
    Declare @experimentGroupDefined tinyint = 0

    If Len(@batchIDs) > 0
    Begin
        INSERT INTO #Tmp_BatchIDs( Batch_ID )
        SELECT VALUE
        FROM dbo.parse_delimited_integer_list ( @batchIDs, ',' )
        WHERE VALUE <> 0
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @myRowCount = 0
        Begin
            If @batchIDs = '0'
                RAISERROR('Invalid requested run batch ID; must be a positive integer, not zero', 11, 14)
            Else
                RAISERROR('Invalid list of requested run batch IDs; integer not found: "%s"', 11, 14, @batchIDs)
        End

        If @myRowCount = 1
            Set @batchDescription = 'batch ' + @batchIDs
        Else
            Set @batchDescription = 'batches ' + @batchIDs

        If Not Exists (Select * From T_Requested_Run_Batches WHERE ID In (Select Batch_ID From #Tmp_BatchIDs))
        Begin
            RAISERROR('Could not find entry in database for requested run %s', 11, 14, @batchDescription)
        End
        Else
        Begin
            Set @batchDefined = 1
        End
    End

    If @dataPackageID > 0
    Begin
        If Not Exists (Select * From S_V_Data_Package_Export WHERE ID = @dataPackageID)
        Begin
            RAISERROR('Could not find entry in database for data package ID "%d"', 11, 14, @dataPackageID)
        End
        Else
        Begin
            Set @dataPackageDefined = 1
        End
    End

    If @experimentGroupID > 0
    Begin
        If Not Exists (Select * From T_Experiment_Groups WHERE Group_ID = @experimentGroupID)
        Begin
            RAISERROR('Could not find entry in database for experiment group ID "%d"', 11, 14, @experimentGroupID)
        End
        Else
        Begin
            Set @experimentGroupDefined = 1
        End
    End

    If @batchDefined = 0 And @dataPackageDefined = 0 And @experimentGroupDefined = 0
    Begin
        RAISERROR('Must define a requested run batch, data package, and/or experiment group', 11, 14)
    End

    ---------------------------------------------------
    -- Force values of some properties for add mode
    ---------------------------------------------------

    If @mode like '%add%'
    Begin
        Set @state = 'New'
        Set @assignedPersonnel = 'na'
    End

    ---------------------------------------------------
    -- Validate requested and assigned personnel
    -- Names should be in the form "Last Name, First Name (Username)"
    ---------------------------------------------------

    Declare @result Int

    Exec @result = validate_request_users
        @requestName, 'add_update_data_analysis_request',
        @requestedPersonnel = @requestedPersonnel Output,
        @assignedPersonnel = @assignedPersonnel Output,
        @requireValidRequestedPersonnel= 0,
        @message = @message Output

    If @result > 0
    Begin
        If IsNull(@message, '') = ''
        Begin
            Set @message = 'Error validating the requested and assigned personnel'
        End

        RAISERROR (@message, 11, 37)
    End

    ---------------------------------------------------
    -- Convert state name to ID
    ---------------------------------------------------

    Declare @stateID int = 0
    --
    SELECT  @stateID = State_ID
    FROM  T_Data_Analysis_Request_State_Name
    WHERE State_Name = @state
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
        RAISERROR ('Error trying to resolving state name', 11, 83)
    --
    If @stateID = 0
        RAISERROR ('No entry could be found in database for state "%s"', 11, 23, @state)

    ---------------------------------------------------
    -- Validate the work package
    ---------------------------------------------------

    If @batchDefined > 0 And IsNull(@workPackage, '') In ('', 'na', 'none')
    Begin
        -- Auto-define using requests in the batch(s)
        --
        SELECT TOP 1 @workPackage = Work_Package
        FROM ( SELECT RDS_WorkPackage AS Work_Package,
                      Count(*) AS Requests
               FROM T_Requested_Run RR
                    INNER JOIN #Tmp_BatchIDs
                      ON RR.RDS_BatchID = #Tmp_BatchIDs.Batch_ID
               WHERE IsNull(RDS_WorkPackage, '') NOT IN ('', 'na', 'none')
               GROUP BY RDS_WorkPackage ) StatsQ
        ORDER BY Requests DESC
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @myRowCount > 0 And @mode Like 'preview%'
        Begin
            Print 'Set Work Package to ' + @WorkPackage + ' based on requests in ' + @batchDescription
        End
    End

    Declare @allowNoneWP tinyint = 0

    exec @myError = validate_wp
                        @workPackage,
                        @allowNoneWP,
                        @msg output

    If @myError <> 0
        RAISERROR ('validate_wp: %s', 11, 1, @msg)

    If Exists (SELECT * FROM T_Charge_Code WHERE Charge_Code = @workPackage And Deactivated = 'Y')
    Begin
        Set @message = dbo.append_to_text(@message, 'Warning: Work Package ' + @workPackage + ' is deactivated', 0, '; ', 1024)
    End
    Else
    Begin
        If Exists (SELECT * FROM T_Charge_Code WHERE Charge_Code = @workPackage And Charge_Code_State = 0)
        Begin
            Set @message = dbo.append_to_text(@message, 'Warning: Work Package ' + @workPackage + ' is likely deactivated', 0, '; ', 1024)
        End
    End

    -- Make sure the Work Package is capitalized properly
    --
    SELECT @workPackage = Charge_Code
    FROM T_Charge_Code
    WHERE Charge_Code = @workPackage

    ---------------------------------------------------
    -- Determine the number of datasets in the batch(s), data package,
    -- and/or experiment group for this Data Analysis Request
    ---------------------------------------------------

    CREATE TABLE #Tmp_DatasetCountsByContainerType (
        ContainerType varchar(24) NOT NULL,
        ContainerID   Int Not Null,
        DatasetCount  int NOT Null,
        SortWeight    int NOT NULL,
    )

    Declare @campaign varchar(128)
    Declare @organism  varchar(128)
    Declare @datasetCount int = 0
    Declare @eusProposalID varchar(10)
    Declare @containerID int

    If @batchDefined > 0
    Begin
        INSERT INTO #Tmp_DatasetCountsByContainerType( ContainerType, ContainerID, SortWeight, DatasetCount )
        SELECT 'Batch', RR.RDS_BatchID, 2 AS SortWeight, Count(*) AS DatasetCount
        FROM T_Requested_Run RR
             INNER JOIN #Tmp_BatchIDs
               ON RR.RDS_BatchID = #Tmp_BatchIDs.Batch_ID
        GROUP BY RR.RDS_BatchID
    End

    If @dataPackageDefined > 0
    Begin
        INSERT INTO #Tmp_DatasetCountsByContainerType( ContainerType, ContainerID, SortWeight, DatasetCount )
        SELECT 'Data Package', @dataPackageID, 1 As SortWeight, Count(DISTINCT D.Dataset_ID) AS DatasetCount
        FROM S_V_Data_Package_Datasets_Export DataPkgDatasets
             INNER JOIN T_Dataset D
               ON DataPkgDatasets.Dataset_ID = D.Dataset_ID
        WHERE DataPkgDatasets.Data_Package_ID = @dataPackageID
    End

    If @experimentGroupDefined > 0
    Begin
        INSERT INTO #Tmp_DatasetCountsByContainerType( ContainerType, ContainerID, SortWeight, DatasetCount )
        SELECT 'Experiment Group', @experimentGroupID, 3 As SortWeight, Count(DISTINCT D.Dataset_ID) AS DatasetCount
        FROM T_Experiment_Group_Members E
             INNER JOIN T_Dataset D
               ON E.Exp_ID = D.Exp_ID
        WHERE E.Group_ID = @experimentGroupID
    End

    ---------------------------------------------------
    -- Determine the representative campaign, organism, dataset count, and EUS_Proposal_ID
    -- Use the container type with the most datasets, sorting by SortWeight if ties
    ---------------------------------------------------

    Declare @preferredContainer varchar(24) = ''
    Declare @representativeBatchID Int = null

    SELECT TOP 1 @preferredContainer = ContainerType,
                 @containerID = ContainerID,
                 @datasetCount = DatasetCount
    FROM #Tmp_DatasetCountsByContainerType
    WHERE DatasetCount > 0
    ORDER BY DatasetCount DESC, SortWeight

    If @mode Like 'preview%'
    Begin
        SELECT *, Case When ContainerType = @preferredContainer Then 'Use for campaign, organism, and EUS proposal lookup' Else '' End As Comment
        FROM #Tmp_DatasetCountsByContainerType
        ORDER BY DatasetCount DESC, SortWeight
    End

    If @preferredContainer = 'Batch'
    Begin
        Set @representativeBatchID = @containerID

        -- Use all batches for the dataset count
        SELECT @datasetCount = Count(*)
        FROM T_Requested_Run RR
             INNER JOIN #Tmp_BatchIDs
               ON RR.RDS_BatchID = #Tmp_BatchIDs.Batch_ID

        SELECT TOP 1 @campaign = Campaign
        FROM ( SELECT C.Campaign_Num AS Campaign,
                      Count(*) AS Experiments
               FROM T_Requested_Run R
                    INNER JOIN T_Experiments E
                      ON R.Exp_ID = E.Exp_ID
                    INNER JOIN T_Campaign C
                      ON E.EX_campaign_ID = C.Campaign_ID
               WHERE R.RDS_BatchID = @representativeBatchID
               GROUP BY C.Campaign_Num ) StatsQ
        ORDER BY StatsQ.Experiments DESC

        SELECT TOP 1 @organism = Organism
        FROM ( SELECT Org.OG_name AS Organism,
                      Count(*) AS Organisms
               FROM T_Requested_Run R
                    INNER JOIN T_Experiments E
                      ON R.Exp_ID = E.Exp_ID
                    INNER JOIN T_Organisms Org
                      ON E.EX_organism_ID = Org.Organism_ID
               WHERE R.RDS_BatchID = @representativeBatchID
               GROUP BY Org.OG_name ) StatsQ
        ORDER BY StatsQ.Organisms DESC

        SELECT TOP 1 @eusProposalID = EUS_Proposal_ID
        FROM ( SELECT R.RDS_EUS_Proposal_ID AS EUS_Proposal_ID,
                      Count(*) AS Requests
               FROM T_Requested_Run R
               WHERE R.RDS_BatchID = @representativeBatchID
               GROUP BY R.RDS_EUS_Proposal_ID ) StatsQ
        ORDER BY StatsQ.Requests DESC
    End
    Else If @preferredContainer = 'Data Package'
    Begin
        SELECT TOP 1 @campaign = Campaign
        FROM ( SELECT C.Campaign_Num AS Campaign,
                      Count(*) AS Experiments
               FROM S_V_Data_Package_Datasets_Export DataPkgDatasets
                    INNER JOIN T_Dataset D
                      ON DataPkgDatasets.Dataset_ID = D.Dataset_ID
                    INNER JOIN T_Experiments E
                      ON D.Exp_ID = E.Exp_ID
                    INNER JOIN T_Campaign C
                      ON E.EX_campaign_ID = C.Campaign_ID
               WHERE DataPkgDatasets.Data_Package_ID = @dataPackageID
               GROUP BY C.Campaign_Num ) StatsQ
        ORDER BY StatsQ.Experiments DESC

        SELECT TOP 1 @organism = Organism
        FROM ( SELECT Org.OG_name AS Organism,
                      Count(*) AS Organisms
               FROM S_V_Data_Package_Datasets_Export DataPkgDatasets
                    INNER JOIN T_Dataset D
                      ON DataPkgDatasets.Dataset_ID = D.Dataset_ID
                    INNER JOIN T_Experiments E
                      ON D.Exp_ID = E.Exp_ID
                    INNER JOIN T_Organisms Org
                      ON E.EX_organism_ID = Org.Organism_ID
               WHERE DataPkgDatasets.Data_Package_ID = @dataPackageID
               GROUP BY Org.OG_name ) StatsQ
        ORDER BY StatsQ.Organisms DESC

        SELECT TOP 1 @eusProposalID = EUS_Proposal_ID
        FROM ( SELECT R.RDS_EUS_Proposal_ID AS EUS_Proposal_ID,
                      Count(*) AS Requests
               FROM S_V_Data_Package_Datasets_Export DataPkgDatasets
                    INNER JOIN T_Dataset D
                      ON DataPkgDatasets.Dataset_ID = D.Dataset_ID
                    INNER JOIN T_Requested_Run R
                      ON D.Dataset_ID = R.DatasetID
               WHERE DataPkgDatasets.Data_Package_ID = @dataPackageID
               GROUP BY R.RDS_EUS_Proposal_ID ) StatsQ
        ORDER BY StatsQ.Requests DESC

    End
    Else If @preferredContainer = 'Experiment Group'
    Begin
        SELECT TOP 1 @campaign = Campaign
        FROM ( SELECT C.Campaign_Num AS Campaign,
                      Count(*) AS Experiments
               FROM T_Experiment_Group_Members EG
                    INNER JOIN T_Experiments E
                      ON EG.Exp_ID = E.Exp_ID
                    INNER JOIN T_Campaign C
                      ON E.EX_campaign_ID = C.Campaign_ID
               WHERE EG.Group_ID = @experimentGroupID
               GROUP BY C.Campaign_Num ) StatsQ
        ORDER BY StatsQ.Experiments DESC

        SELECT TOP 1 @organism = Organism
        FROM ( SELECT Org.OG_name AS Organism,
                      Count(*) AS Organisms
               FROM T_Experiment_Group_Members EG
                    INNER JOIN T_Experiments E
                      ON EG.Exp_ID = E.Exp_ID
                    INNER JOIN T_Organisms Org
                      ON E.EX_organism_ID = Org.Organism_ID
               WHERE EG.Group_ID = @experimentGroupID
               GROUP BY Org.OG_name ) StatsQ
        ORDER BY StatsQ.Organisms DESC

        SELECT TOP 1 @eusProposalID = EUS_Proposal_ID
        FROM ( SELECT R.RDS_EUS_Proposal_ID AS EUS_Proposal_ID,
                      Count(*) AS Requests
               FROM T_Experiment_Group_Members EG
                    INNER JOIN T_Experiments E
                      ON EG.Exp_ID = E.Exp_ID
                    INNER JOIN T_Dataset D
                      ON E.Exp_ID = D.Dataset_ID
                    INNER JOIN T_Requested_Run R
                      ON D.Dataset_ID = R.DatasetID
               WHERE EG.Group_ID = @experimentGroupID
               GROUP BY R.RDS_EUS_Proposal_ID ) StatsQ
        ORDER BY StatsQ.Requests DESC

    End

    If @batchDefined > 0 And @representativeBatchID Is Null
    Begin
        -- Either @preferredContainer is not 'Batch' or none of the batches has a requested run with a dataset
        --
        SELECT TOP 1 @representativeBatchID = Batch_ID
        FROM ( SELECT RR.RDS_BatchID As Batch_ID,
                      Count(*) AS Requests
               FROM T_Requested_Run RR
                    INNER JOIN #Tmp_BatchIDs
                      ON RR.RDS_BatchID = #Tmp_BatchIDs.Batch_ID
               GROUP BY RR.RDS_BatchID ) StatsQ
        ORDER BY Requests Desc
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @myRowCount = 0
        Begin
            -- None of the batches has any requested runs
            --
            SELECT TOP 1 @representativeBatchID = Batch_ID
            FROM #Tmp_BatchIDs
            ORDER BY Batch_ID
        End
    End

    If @mode Like 'preview%'
    Begin
        SELECT @campaign AS Campaign,
               @organism AS Organism,
               @eusProposalID AS EUS_Proposal_ID,
               @datasetCount AS Dataset_Count
    End

    ---------------------------------------------------
    -- Is entry already in database?
    ---------------------------------------------------

    If @mode like '%update%'
    Begin
        -- Cannot update a non-existent entry
        --
        Declare @tmp int = 0
        Declare @currentAssignedPersonnel varchar(256)
        Set @currentStateID = 0
        --
        SELECT
            @tmp = ID,
            @currentStateID = State,
            @currentAssignedPersonnel = Assigned_Personnel
        FROM  T_Data_Analysis_Request
        WHERE ID = @id
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0 OR @tmp = 0
            RAISERROR ('No entry could be found in database for update', 11, 7)

        -- Limit who can make changes if in "closed" state
        --
        If @currentStateID = 4 AND NOT EXISTS (SELECT * FROM V_Data_Analysis_Request_User_Picklist WHERE username = @callingUser)
            RAISERROR ('Changes to entry are not allowed if it is in the "Closed" state', 11, 11)

        -- Don't allow change to "Analysis in Progress" unless someone has been assigned
        --
        If @state = 'Analysis in Progress' AND ((@assignedPersonnel = '') OR (@assignedPersonnel = 'na'))
            RAISERROR ('Assigned personnel must be selected when the state is "Analysis in Progress"', 11, 84)
    End

    If @mode like '%add%'
    Begin
        -- Make sure the work package is not inactive
        --
        Declare @activationState tinyint = 10
        Declare @activationStateName varchar(128)

        SELECT @activationState = CCAS.Activation_State,
               @activationStateName = CCAS.Activation_State_Name
        FROM T_Charge_Code CC
             INNER JOIN T_Charge_Code_Activation_State CCAS
               ON CC.Activation_State = CCAS.Activation_State
        WHERE (CC.Charge_Code = @workPackage)

        If @activationState >= 3
            RAISERROR ('Cannot use inactive Work Package "%s" for a new Data Analysis Request', 11, 8, @workPackage)
    End

    ---------------------------------------------------
    -- Check for name collisions
    ---------------------------------------------------
    --
    If @mode like '%add%'
    Begin
        IF EXISTS (SELECT * FROM T_Data_Analysis_Request WHERE Request_Name = @requestName)
            RAISERROR ('Cannot add: Request "%s" already in database', 11, 8, @requestName)

    End
    Else
    Begin
        IF EXISTS (SELECT * FROM T_Data_Analysis_Request WHERE Request_Name = @requestName AND ID <> @id)
            RAISERROR ('Cannot rename: Request "%s" already in database', 11, 8, @requestName)
    End

    Set @logErrors = 1

    Declare @transName varchar(32) = 'add_update_data_analysis_request'

    ---------------------------------------------------
    -- Action for add mode
    ---------------------------------------------------
    --
    If @mode = 'add'
    Begin
        Begin transaction @transName

        INSERT INTO T_Data_Analysis_Request (
            Request_Name,
            Analysis_Type,
            Requester_PRN,
            Description,
            Analysis_Specifications,
            Comment,
            Representative_Batch_ID,
            Data_Package_ID,
            Exp_Group_ID,
            Work_Package,
            Requested_Personnel,
            Assigned_Personnel,
            Priority,
            Reason_For_High_Priority,
            Estimated_Analysis_Time_Days,
            State,
            State_Comment,
            Campaign,
            Organism,
            EUS_Proposal_ID,
            Dataset_Count
        ) VALUES (
            @requestName,
            @analysisType,
            @requesterUsername,
            @description,
            @analysisSpecifications,
            @comment,
            Case When @batchDefined > 0 Then @representativeBatchID Else Null End,
            Case When @dataPackageDefined > 0 Then @dataPackageID Else Null End,
            Case When @experimentGroupDefined > 0 Then @experimentGroupID Else Null End,
            @workPackage,
            @requestedPersonnel,
            @assignedPersonnel,
            @priority,
            @reasonForHighPriority,
            Case When @allowUpdateEstimatedAnalysisTime > 0 Then @estimatedAnalysisTimeDays Else 0 End,
            @stateID,
            @stateComment,
            @campaign,
            @organism,
            @eusProposalID,
            @DatasetCount
        )
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
            RAISERROR ('Insert operation failed: %d', 11, 7, @myError)

        -- Return ID of newly created entry
        --
        Set @id = SCOPE_IDENTITY()

        commit transaction @transName

        -- If @callingUser is defined, update Entered_By in T_Data_Analysis_Request_Updates
        If Len(@callingUser) > 0
        Begin
            Exec alter_entered_by_user 'T_Data_Analysis_Request_Updates', 'Request_ID', @id, @callingUser,
                                    @entryDateColumnName='Entered', @enteredByColumnName='Entered_By'
        End

        If @batchDefined > 0
        Begin
            INSERT INTO T_Data_Analysis_Request_Batch_IDs( Request_ID, Batch_ID )
            SELECT @id, Batch_ID
            FROM #Tmp_BatchIDs
        End
    End -- Add mode

    ---------------------------------------------------
    -- Action for update mode
    ---------------------------------------------------
    --
    If @mode = 'update'
    Begin
        Declare @currentEstimatedAnalysisTimeDays Int

        SELECT @currentEstimatedAnalysisTimeDays = Estimated_Analysis_Time_Days
        FROM T_Data_Analysis_Request
        WHERE ID = @id

        Begin transaction @transName

        UPDATE T_Data_Analysis_Request
        SET Request_Name = @requestName,
            Analysis_Type = @analysisType,
            Requester_PRN = @requesterUsername,
            Description = @description,
            Analysis_Specifications = @analysisSpecifications,
            Comment = @comment,
            Representative_Batch_ID = Case When @batchDefined > 0 Then @representativeBatchID Else Null End,
            Data_Package_ID = Case When @dataPackageDefined > 0 Then @dataPackageID Else Null End,
            Exp_Group_ID = Case When @experimentGroupDefined > 0 Then @experimentGroupID Else Null End,
            Work_Package = @workPackage,
            Requested_Personnel = @requestedPersonnel,
            Assigned_Personnel = @assignedPersonnel,
            Priority = @priority,
            Reason_For_High_Priority = @reasonForHighPriority,
            Estimated_Analysis_Time_Days =
              CASE
                  WHEN @allowUpdateEstimatedAnalysisTime > 0 THEN @estimatedAnalysisTimeDays
                  ELSE Estimated_Analysis_Time_Days
              END,
            State = @stateID,
            State_Changed = Case When @currentStateID = @stateID Then State_Changed Else GetDate() End,
            State_Comment = @stateComment,
            Campaign = @campaign,
            Organism = @organism,
            EUS_Proposal_ID = @eusProposalID,
            Dataset_Count = @datasetCount
        WHERE ID = @id
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
            RAISERROR ('Update operation failed: "%d"', 11, 4, @id)

        commit transaction @transName

        -- If @callingUser is defined, update Entered_By in T_Data_Analysis_Request_Updates
        If Len(@callingUser) > 0
        Begin
            Exec alter_entered_by_user 'T_Data_Analysis_Request_Updates', 'Request_ID', @id, @callingUser,
                                    @entryDateColumnName='Entered', @enteredByColumnName='Entered_By'
        End

        If @currentEstimatedAnalysisTimeDays <> @estimatedAnalysisTimeDays And @allowUpdateEstimatedAnalysisTime = 0
        Begin
            Set @msg = 'Not updating estimated analysis time since user does not have permission'
            Set @message = dbo.append_to_text(@message, @msg, 0, '; ', 1024)
        End

        If @batchDefined > 0
        Begin
            MERGE T_Data_Analysis_Request_Batch_IDs AS t
            USING (SELECT @id As Request_ID, Batch_ID FROM #Tmp_BatchIDs) as s
            ON ( t.Batch_ID = s.Batch_ID AND t.Request_ID = s.Request_ID)
            WHEN NOT MATCHED BY TARGET THEN
                INSERT(Request_ID, Batch_ID)
                VALUES(s.Request_ID, s.Batch_ID)
            WHEN NOT MATCHED BY SOURCE And t.Request_ID = @id THEN Delete;
        End
        Else
        Begin
            DELETE FROM T_Data_Analysis_Request_Batch_IDs
            WHERE Request_ID = @id;
        End

    End -- update mode

    End Try
    Begin Catch
        EXEC format_error_message @message output, @myError output

        -- rollback any open transactions
        If (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;

        If @logErrors > 0
        Begin
            Declare @logMessage varchar(1024) = @message + '; Request ' + @requestName
            exec post_log_entry 'Error', @logMessage, 'add_update_data_analysis_request'
        End

    End Catch

    Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[add_update_data_analysis_request] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[add_update_data_analysis_request] TO [DMS_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[add_update_data_analysis_request] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[add_update_data_analysis_request] TO [Limited_Table_Write] AS [dbo]
GO
