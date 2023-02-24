/****** Object:  StoredProcedure [dbo].[add_experiment_fractions] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[add_experiment_fractions]
/****************************************************
**
**  Desc:   Creates a group of new experiments in DMS,
**          linking back to the parent experiment
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**  Date:   05/28/2005
**          05/29/2005 grk - Added mods to better work with entry page
**          05/31/2005 grk - Added mods for separate group members table
**          06/10/2005 grk - Added handling for sample prep request
**          10/04/2005 grk - Added call to add_experiment_biomaterial
**          10/04/2005 grk - Added override for request ID
**          10/28/2005 grk - Added handling for internal standard
**          11/11/2005 grk - Added handling for postdigest internal standard
**          12/20/2005 grk - Added handling for separate user
**          02/06/2006 grk - Increased maximum count
**          01/13/2007 grk - Switched to organism ID instead of organism name (Ticket #360)
**          09/27/2007 mem - Moved the copying of AuxInfo to occur after the new experiments have been created and to use copy_aux_info_multi_id (Ticket #538)
**          10/22/2008 grk - Added container field (Ticket http://prismtrac.pnl.gov/trac/ticket/697)
**          07/16/2009 grk - Added wellplate and well fields (http://prismtrac.pnl.gov/trac/ticket/741)
**          07/31/2009 grk - Added prep LC run field (http://prismtrac.pnl.gov/trac/ticket/743)
**          09/13/2011 grk - Added researcher to experiment group
**          10/03/2011 grk - Added try-catch error handling
**          11/10/2011 grk - Added Tab field
**          11/15/2011 grk - Added handling for experiment alkylation field
**          02/23/2016 mem - Add Set XACT_ABORT on
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          08/22/2017 mem - Copy TissueID
**          08/25/2017 mem - Use TissueID from the Sample Prep Request if @requestOverride is not "parent" and if the prep request has a tissue defined
**          09/06/2017 mem - Fix data type for @tissueID
**          11/29/2017 mem - No longer pass @cellCultureList to add_experiment_biomaterial since it now uses temp table #Tmp_ExpToCCMap
**                         - Remove references to the Cell_Culture_List field in T_Experiments (procedure add_experiment_biomaterial calls update_cached_experiment_component_names)
**                         - Call add_experiment_reference_compound
**          01/04/2018 mem - Update fields in #Tmp_ExpToRefCompoundMap, switching from Compound_Name to Compound_IDName
**          12/03/2018 mem - Add parameter @suffix
**                         - Add support for @mode = 'Preview'
**          12/04/2018 mem - Insert plex member info into T_Experiment_Plex_Members if defined for the parent experiment
**          12/06/2018 mem - Call update_experiment_group_member_count to update T_Experiment_Groups
**          01/24/2019 mem - Add parameters @nameSearch, @nameReplace, and @addUnderscore
**          12/08/2020 mem - Lookup U_PRN from T_Users using the validated user ID
**          02/15/2021 mem - If the parent experiment has a TissueID defined, use it, even if the Sample Prep Request is not "parent" (for @requestOverride)
**                         - No longer copy the parent experiment concentration to the fractions
**          06/01/2021 mem - Raise an error if @mode is invalid
**          04/12/2022 mem - Do not log data validation errors to T_Log_Entries
**          11/18/2022 mem - Rename parameter to @groupName
**          11/25/2022 mem - Rename parameter to @wellplateName
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @parentExperiment varchar(128),             -- Parent experiment for group (must already exist)
    @groupType varchar(20) = 'Fraction',        -- Must be 'Fraction'
    @suffix varchar(20) = '',                   -- Text to append to the parent experiment name, prior to adding the fraction number
    @nameSearch  varchar(128) = '',             -- Text to find in the parent experiment name, to be replaced by @nameReplace
    @nameReplace varchar(128) = '',             -- Replacement text
    @groupName varchar(128),                    -- User-defined name for this experiment group (aka fraction group); previously @tab
    @description varchar(512),                  -- Purpose of group
    @totalCount int,                            -- Number of new experiments to automatically create
    @addUnderscore varchar(12) = 'Yes',         -- When Yes (or 1 or ''), add an underscore before the fraction number; when @suffix is defined, it is helpful to set this to 'No'
    @groupID int output,                        -- ID of newly created experiment group
    @requestOverride varchar(12) = 'parent',    -- ID of sample prep request for fractions (if different than parent experiment)
    @internalStandard varchar(50) = 'parent',
    @postdigestIntStd varchar(50) = 'parent',
    @researcher varchar(50) = 'parent',
    @wellplateName varchar(64) output,
    @wellNumber varchar(8) output,
    @container varchar(128) = 'na',             -- na, "parent", "-20", or actual container ID
    @prepLCRunID int,
    @mode varchar(12),                          -- 'add' or 'preview'; when previewing, will show the names of the new fractions
    @message varchar(512) output,
    @callingUser varchar(128) = ''
)
AS
    Set XACT_ABORT, nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Declare @fractionCount int = 0
    Declare @maxCount smallint = 200

    Declare @fractionNumberText varchar(2)

    Declare @fullFractionCount int
    Declare @newExperimentID int

    Declare @msg varchar(512)

    Declare @startingIndex int = 1      -- Initial index for automatic naming of new experiments
    Declare @step int = 1               -- Step interval in index
    Declare @fractionsCreated int = 0

    -- T_Experiments column variables
    --
    Declare @parentExperimentID int = 0
    Declare @baseFractionName varchar(128)
    Declare @researcherUsername varchar(50)
    Declare @organismID int
    Declare @reason varchar(500)
    Declare @comment varchar(500)
    Declare @created datetime
    Declare @sampleConc varchar(50)
    Declare @labNotebook varchar(50)
    Declare @campaignID int
    Declare @labelling varchar(64)
    Declare @enzymeID int
    Declare @samplePrepRequest int
    Declare @internalStandardID int
    Declare @postdigestIntStdID int
    Declare @parentContainerID int = 0
    Declare @alkylation char(1)
    Declare @tissueID varchar(24)

    Declare @experimentIDList varchar(8000) = ''

    Declare @materialIDList varchar(8000) = ''
    Declare @fractionNamePreviewList varchar(8000) = ''

    Declare @wellPlateMode varchar(12)
    Declare @logErrors tinyint = 0

    Begin TRY

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    If IsNull(@totalCount, 0) <= 0
    Begin
        Set @message = 'Number of child experments cannot be 0'
        RAISERROR (@message, 11, 4)
    End

    -- Don't allow too many child experiments to be created
    --
    If @totalCount > @maxCount
    Begin
        Set @message = 'Cannot create more than ' + convert(varchar(12), @maxCount) + ' child experments'
        RAISERROR (@message, 11, 4)
    End

    -- Make sure that we don't overflow our alloted space for digits
    --
    If @startingIndex + (@totalCount * @step) > 999
    Begin
        Set @message = 'Automatic numbering parameters will require too many digits'
        RAISERROR (@message, 11, 5)
    End

    Set @GroupType = LTrim(RTrim(IsNull(@GroupType, '')))

    If Len(@GroupType) = 0
        Set @GroupType = 'Fraction'
    Else
    Begin
        If @GroupType <> 'Fraction'
        Begin
            Set @message = 'The only supported @GroupType is "Fraction"'
            RAISERROR (@message, 11, 6)
        End
    End

    Set @suffix = IsNull(@suffix, '')
    Set @nameSearch = IsNull(@nameSearch, '')
    Set @nameReplace = IsNull(@nameReplace, '')

    Set @addUnderscore = IsNull(@addUnderscore, 'Yes')

    Set @requestOverride = LTrim(RTrim(IsNull(@requestOverride, 'parent')))
    Set @internalStandard = LTrim(RTrim(IsNull(@internalStandard, 'parent')))
    Set @postdigestIntStd = LTrim(RTrim(IsNull(@postdigestIntStd, 'parent')))
    Set @researcher = LTrim(RTrim(IsNull(@researcher, 'parent')))

    Set @message = ''

    Set @mode = ISNULL(@mode, '')

    If Not @mode in ('add', 'preview')
    Begin
        RAISERROR ('Invalid mode: should be "add" or "preview", not "%s"', 11, 117, @mode)
    End

    -- Create temporary tables to hold cell cultures and reference compounds associated with the parent experiment
    --
    CREATE TABLE #Tmp_ExpToCCMap (
        CC_Name varchar(128) not null,
        CC_ID int null
    )

    CREATE TABLE #Tmp_ExpToRefCompoundMap (
        Compound_IDName varchar(128) not null,
        Colon_Pos int null,
        Compound_ID int null
    )

    ---------------------------------------------------
    -- Get information for parent experiment
    ---------------------------------------------------

    SELECT @parentExperimentID = Exp_ID,
           @baseFractionName = Experiment_Num,
           @researcherUsername = EX_researcher_PRN,
           @organismID = EX_organism_ID,
           @reason = EX_reason,
           @comment = EX_comment,
           @created = EX_created,
           @labNotebook = EX_lab_notebook_ref,
           @campaignID = EX_campaign_ID,
           @labelling = EX_Labelling,
           @enzymeID = EX_enzyme_ID,
           @samplePrepRequest = EX_sample_prep_request_ID,
           @internalStandardID = EX_internal_standard_ID,
           @postdigestIntStdID = EX_postdigest_internal_std_ID,
           @parentContainerID = EX_Container_ID,
           @alkylation = EX_Alkylation,
           @tissueID = EX_Tissue_ID
    FROM T_Experiments
    WHERE Experiment_Num = @parentExperiment
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0 OR @parentExperimentID = 0
    Begin
        Set @message = 'Could not find parent experiment named ' + @parentExperiment
        RAISERROR (@message, 11, 7)
    End

    -- Make sure @parentExperiment is capitalized properly
    Set @parentExperiment = @baseFractionName

    -- Search/replace, if defined
    If Len(@nameSearch) > 0
    Begin
        Set @baseFractionName = Replace(@baseFractionName, @nameSearch, @nameReplace)
    End

    -- Append the suffix, if defined
    If Len(@suffix) > 0
    Begin
        If Substring(@suffix, 1, 1) IN ('_', '-')
            Set @baseFractionName = @baseFractionName + @suffix
        Else
            Set @baseFractionName = @baseFractionName + '_' + @suffix
    End

    ---------------------------------------------------
    -- Cache the cell culture mapping
    ---------------------------------------------------
    --
    INSERT INTO #Tmp_ExpToCCMap( CC_Name,
                                 CC_ID )
    SELECT CC.CC_Name,
           CC.CC_ID
    FROM T_Experiment_Cell_Cultures ECC
         INNER JOIN T_Cell_Culture CC
           ON ECC.CC_ID = CC.CC_ID
    WHERE ECC.Exp_ID = @parentExperimentID
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount


    ---------------------------------------------------
    -- Cache the reference compound mapping
    ---------------------------------------------------
    --
    INSERT INTO #Tmp_ExpToRefCompoundMap( Compound_IDName,
                                          Compound_ID )
    SELECT Cast(RC.Compound_ID As varchar(12)),
           RC.Compound_ID
    FROM T_Experiment_Reference_Compounds ERC
         INNER JOIN T_Reference_Compound RC
           ON ERC.Compound_ID = RC.Compound_ID
    WHERE ERC.Exp_ID = @parentExperimentID
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount


    ---------------------------------------------------
    -- Set up and validate wellplate values
    ---------------------------------------------------
    --
    Declare @wellIndex int
    exec @myError = validate_wellplate_loading
                        @wellplateName output,
                        @wellNumber output,
                        @totalCount,
                        @wellIndex output,
                        @message output
    If @myError <> 0
    Begin
        RAISERROR (@message, 11, 8)
    End

    Set @logErrors = 1

    ---------------------------------------------------
    -- Assure that wellplate is in wellplate table (if set)
    ---------------------------------------------------
    --
    If Not @wellplateName Is Null
    Begin
        If @wellplateName = 'new'
        Begin
            Set @wellplateName = '(generate name)'
            Set @wellPlateMode = 'add'
        End
        Else
        Begin
            Set @wellPlateMode = 'assure'
        End
        --
        Declare @note varchar(128) = 'Created by experiment fraction entry (' + @parentExperiment + ')'
        exec @myError = add_update_wellplate
                            @wellplateName output,
                            @note,
                            @wellPlateMode,
                            @message output,
                            @callingUser
        If @myError <> 0
        Begin
            return @myError
        End
    End

    ---------------------------------------------------
    -- Possibly override prep request ID
    ---------------------------------------------------

    Declare @prepRequestTissueID varchar(24) = Null

    If @requestOverride <> 'parent'
    Begin
        Set @samplePrepRequest = Try_Cast(@requestOverride as int)

        If @samplePrepRequest Is Null
        Begin
            Set @logErrors = 0
            Set @message = 'Prep request ID is not an integer: ' + @requestOverride
            RAISERROR (@message, 11, 9)
        End

        SELECT @prepRequestTissueID = Tissue_ID
        FROM T_Sample_Prep_Request
        WHERE ID = @samplePrepRequest
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0 OR @myRowCount <> 1
        Begin
            Set @logErrors = 0
            Set @message = 'Could not find sample prep request: ' + @requestOverride
            RAISERROR (@message, 11, 10)
        End

        If IsNull(@tissueID, '') = '' AND IsNull(@prepRequestTissueID, '') <> ''
        Begin
            Set @tissueID = @prepRequestTissueID
        End
    End

    ---------------------------------------------------
    -- Resolve predigest internal standard ID
    ---------------------------------------------------
    If @internalStandard <> 'parent'
    Begin
        Declare @tmpID int = Null
        --
        SELECT @tmpID = Internal_Std_Mix_ID
        FROM T_Internal_Standards
        WHERE (Name = @internalStandard)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myRowCount = 0
        Begin
            Set @logErrors = 0
            Set @message = 'Could not find entry in database for internal standard "' + @internalStandard + '"'
            RAISERROR (@message, 11, 11)
        End
        Set @internalStandardID = @tmpID
    End

    ---------------------------------------------------
    -- Resolve postdigestion internal standard ID
    ---------------------------------------------------
    --
    If @postdigestIntStd <> 'parent'
    Begin
        Set @tmpID = Null
        --
        SELECT @tmpID = Internal_Std_Mix_ID
        FROM T_Internal_Standards
        WHERE (Name = @postdigestIntStd)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myRowCount = 0
        Begin
            Set @logErrors = 0
            Set @message = 'Could not find entry in database for postdigestion internal standard "' + @tmpID + '"'
            RAISERROR (@message, 11, 12)
        End
        Set @postdigestIntStdID = @tmpID
    End

    ---------------------------------------------------
    -- Resolve researcher
    ---------------------------------------------------
    --
    If @researcher <> 'parent'
    Begin
        Declare @userID int
        execute @userID = get_user_id @researcher

        If @userID > 0
        Begin
            -- SP get_user_id recognizes both a username and the form 'LastName, FirstName (Username)'
            -- Assure that @researcher contains simply the username
            --
            SELECT @researcher = U_PRN
            FROM T_Users
            WHERE ID = @userID
        End
        Else
        Begin
            -- Could not find entry in database for username @researcher
            -- Try to auto-resolve the name

            Declare @newUsername varchar(64)
            Declare @matchCount int

            exec auto_resolve_name_to_username @researcher, @matchCount output, @newUsername output, @userID output

            If @matchCount = 1
            Begin
                -- Single match found; update @researcher
                Set @researcher = @newUsername
            End
            Else
            Begin
                Set @logErrors = 0
                Set @message = 'Could not find entry in database for researcher username "' + @researcher + '"'
                RAISERROR (@message, 11, 13)
            End
        End
        Set @researcherUsername = @researcher
    End

    ---------------------------------------------------
    -- Set up transaction around multiple table modifications
    ---------------------------------------------------

    Declare @transName varchar(32) = 'Add_Batch_Experiment_Entry'
    Set @logErrors = 1

    Begin transaction @transName

    If @mode LIKE '%preview%'
    Begin
        Set @groupID = 0
    End
    Else
    Begin
        ---------------------------------------------------
        -- Make Experiment group entry
        ---------------------------------------------------
        INSERT INTO T_Experiment_Groups (
            EG_Group_Type ,
            Parent_Exp_ID ,
            EG_Description ,
            Prep_LC_Run_ID ,
            EG_Created ,
            Researcher,
            Group_Name
        ) VALUES (
            @groupType ,
            @parentExperimentID ,
            @description ,
            @prepLCRunID ,
            GETDATE() ,
            @researcherUsername,
            @groupName
        )
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
        Begin
            Set @message = 'Failed to insert new group entry into database'
            RAISERROR (@message, 11, 14)
        End

        Set @groupID = SCOPE_IDENTITY()

        ---------------------------------------------------
        -- Add parent experiment to reference group
        ---------------------------------------------------

        INSERT INTO T_Experiment_Group_Members (
            Group_ID,
            Exp_ID
        ) VALUES (
            @groupID,
            @parentExperimentID
        )
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
        Begin
            Set @message = 'Failed to update group reference for experiment'
            RAISERROR (@message, 11, 15)
        End
    End

    ---------------------------------------------------
    -- Insert Fractionated experiment entries
    ---------------------------------------------------
    Declare @newComment varchar(500)
    Declare @newExpName varchar(129)
    Declare @xID int
    Declare @result int
    Declare @wn varchar(8) = @wellNumber
    Declare @nameFractionLinker varchar(1)

    If @addUnderscore In ('No', 'N', '0')
        Set @nameFractionLinker = ''
    Else
        Set @nameFractionLinker = '_'

    While @fractionCount < @totalCount And @myError = 0
    Begin -- <AddFractions>
        -- Build name for new experiment fraction
        --
        Set @fullFractionCount = @startingIndex + @fractionCount
        Set @fractionNumberText = CAST(@fullFractionCount as varchar(3))
        If  @fullFractionCount < 10
        Begin
            Set @fractionNumberText = '0' + @fractionNumberText
        End

        Set @fractionCount = @fractionCount + @step
        Set @newComment = '(Fraction ' + CAST(@fullfractioncount as varchar(3)) + ' of ' + CAST(@totalcount as varchar(3)) + ')'
        Set @newExpName = @baseFractionName + @nameFractionLinker + @fractionNumberText
        Set @fractionsCreated = @fractionsCreated + 1

        -- Verify that experiment name is not duplicated in table
        --
        Set @xID = 0
        execute @xID = get_experiment_id @newExpName
        --
        If @xID <> 0
        Begin
            rollback transaction @transName
            Set @message = 'Failed to add new fraction experiment since existing experiment already exists named: ' + @newExpName
            Set @myError = 51002
            RAISERROR (@message, 11, 16)
        End

        If @fractionsCreated < 4
        Begin
            If LEN(@fractionNamePreviewList) = 0
                Set @fractionNamePreviewList = @newExpName
            Else
                Set @fractionNamePreviewList = @fractionNamePreviewList + ', ' + @newExpName
        End
        Else
        Begin
            If @fractionCount = @totalCount
            Begin
                Set @fractionNamePreviewList = @fractionNamePreviewList + ', ... ' + @newExpName
            End
        End

        If @mode = 'add'
        Begin -- <AddFraction>

            -- Insert new experiment into database
            --
            INSERT INTO [T_Experiments] (
                Experiment_Num,
                EX_researcher_PRN,
                EX_organism_ID,
                EX_reason,
                EX_comment,
                EX_created,
                EX_sample_concentration,
                EX_lab_notebook_ref,
                EX_campaign_ID,
                EX_Labelling,
                EX_enzyme_ID,
                EX_sample_prep_request_ID,
                EX_internal_standard_ID,
                EX_postdigest_internal_std_ID,
                EX_wellplate_num,
                EX_well_num,
                EX_Alkylation,
                EX_Tissue_ID
            ) VALUES (
                @newExpName,
                @researcherUsername,
                @organismID,
                @reason,
                @newComment,
                GETDATE(),
                '? ug/uL',
                @labNotebook,
                @campaignID,
                @labelling,
                @enzymeID,
                @samplePrepRequest,
                @internalStandardID,
                @postdigestIntStdID,
                @wellplateName,
                @wn,
                @alkylation,
                @tissueID
            )
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount
            --
            If @myError <> 0
            Begin
                rollback transaction @transName
                Set @message = 'Insert operation failed!'
                RAISERROR (@message, 11, 17)
            End

            Set @newExperimentID = SCOPE_IDENTITY()

            -- Add the experiment to biomaterial mapping
            -- The stored procedure uses table #Tmp_ExpToCCMap
            --
            execute @result = add_experiment_biomaterial
                                    @newExperimentID,
                                    @updateCachedInfo=0,
                                    @message=@message output
            --
            If @result <> 0
            Begin
                rollback transaction @transName
                Set @msg = 'Could not add experiment cell cultures to database for experiment: "' + @newExpName + '" ' + @message
                RAISERROR (@msg, 11, 18)
            End

            -- Add the experiment to reference compound mapping
            -- The stored procedure uses table #Tmp_ExpToRefCompoundMap
            --
            execute @result = add_experiment_reference_compound
                                    @newExperimentID,
                                    @updateCachedInfo=1,
                                    @message=@message output
            --
            If @result <> 0
            Begin
                rollback transaction @transName
                Set @msg = 'Could not add experiment reference compounds to database for experiment: "' + @newExpName + '" ' + @message
                RAISERROR (@msg, 11, 19)
            End

            ---------------------------------------------------
            -- Add fractionated experiment reference to experiment group
            ---------------------------------------------------

            INSERT INTO T_Experiment_Group_Members (
                Group_ID,
                Exp_ID
            ) VALUES (
                @groupID,
                @newExperimentID
            )
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount
            --
            If @myError <> 0
            Begin
                rollback transaction @transName
                Set @message = 'Failed to update group reference for new experiment'
                RAISERROR (@message, 11, 20)
            End

            ---------------------------------------------------
            -- Append Experiment ID to @experimentIDList and @materialIDList
            ---------------------------------------------------
            --
            If Len(@experimentIDList) > 0
                Set @experimentIDList = @experimentIDList + ','

            Set @experimentIDList = @experimentIDList + Convert(varchar(12), @newExperimentID)

            If Len(@materialIDList) > 0
                Set @materialIDList = @materialIDList + ','

            Set @materialIDList = @materialIDList + 'E:' + Convert(varchar(12), @newExperimentID)

            ---------------------------------------------------
            -- Copy experiment plex info, if defined
            ---------------------------------------------------

            If Exists (SELECT * FROM T_Experiment_Plex_Members WHERE Plex_Exp_ID = @parentExperimentID)
            Begin -- <CopyPlexInfo>
                INSERT INTO T_Experiment_Plex_Members( Plex_Exp_ID,
                                                       Channel,
                                                       Exp_ID,
                                                       Channel_Type_ID,
                                                       [Comment] )
                SELECT @newExperimentID AS Plex_Exp_ID,
                       Channel,
                       Exp_ID,
                       Channel_Type_ID,
                       [Comment]
                FROM T_Experiment_Plex_Members
                WHERE Plex_Exp_ID = @parentExperimentID
                --
                SELECT @myError = @@error, @myRowCount = @@rowcount

                If Len(@callingUser) > 0
                Begin
                    -- Call alter_entered_by_user to alter the Entered_By field in T_Experiment_Plex_Members_History
                    --
                    Exec alter_entered_by_user 'T_Experiment_Plex_Members_History', 'Plex_Exp_ID', @newExperimentID, @CallingUser
                End

            End -- </CopyPlexInfo>
        End -- </AddFraction>

        If @mode = 'add'
        Begin
            ---------------------------------------------------
            -- Update the MemberCount field in T_Experiment_Groups
            -- Note that the count includes the parent experiment
            ---------------------------------------------------
            --
            Exec update_experiment_group_member_count @groupID = @groupID
        End

        ---------------------------------------------------
        -- Increment well number
        ---------------------------------------------------
        --
        If Not @wn Is Null
        Begin
            Set @wellIndex = @wellIndex + 1
            Set @wn = dbo.get_well_number(@wellIndex)
        End

    End -- </AddFractions>

    If @mode LIKE '%Preview%'
    Begin
        SET @message = 'Preview of new fraction names: ' + @fractionNamePreviewList
    End
    Else
    Begin -- <AddToContainer>

        ---------------------------------------------------
        -- Resolve parent container name
        ---------------------------------------------------
        --
        If @container = 'parent'
        Begin
            SELECT @container = Tag
            FROM T_Material_Containers
            WHERE ID = @parentContainerID
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount
            --
            If @myError <> 0
            Begin
                rollback transaction @transName
                Set @message = 'Failed to find parent container'
                RAISERROR (@message, 11, 21)
            End
        End

        ---------------------------------------------------
        -- Move new fraction experiments to container
        ---------------------------------------------------
        --
        exec @result = update_material_items
                        'move_material',
                        @materialIDList,
                        'mixed_material',
                        @container,
                        '',
                        @message output,
                        @callingUser
        If @result <> 0
        Begin
            If @@TRANCOUNT > 0
                rollback transaction @transName
            RAISERROR (@message, 11, 22)
        End

        ---------------------------------------------------
        -- Now copy the aux info from the parent experiment
        -- into the fractionated experiments
        ---------------------------------------------------

        exec @result = copy_aux_info_multi_id
                        @targetName = 'Experiment',
                        @targetEntityIDList = @experimentIDList,
                        @categoryName = '',
                        @subCategoryName = '',
                        @sourceEntityID = @parentExperimentID,
                        @mode = 'copyAll',
                        @message = @message output

        If @result <> 0
        Begin
            If @@TRANCOUNT > 0
                rollback transaction @transName
            Set @message = 'Error copying Aux Info from parent Experiment to fractionated experiments'
            RAISERROR (@message, 11, 23)
        End

        If @message = ''
        Begin
            Set @message = 'New fraction names: ' + @fractionNamePreviewList
        End

    End -- </AddToContainer>

    ---------------------------------------------------
    -- Commit transaction if there were no errors
    ---------------------------------------------------

    commit transaction @transName

    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
    End TRY
    Begin CATCH
        EXEC format_error_message @message output, @myError output

        -- rollback any open transactions
        If (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;

        If @logErrors > 0
        Begin
            Exec post_log_entry 'Error', @message, 'add_experiment_fractions'
        End
    End CATCH

    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[add_experiment_fractions] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[add_experiment_fractions] TO [DMS_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[add_experiment_fractions] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[add_experiment_fractions] TO [Limited_Table_Write] AS [dbo]
GO
