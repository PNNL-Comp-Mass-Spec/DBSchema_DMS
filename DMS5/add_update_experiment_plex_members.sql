/****** Object:  StoredProcedure [dbo].[add_update_experiment_plex_members] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[add_update_experiment_plex_members]
/****************************************************
**
**  Desc:   Adds new or updates existing rows in T_Experiment_Plex_Members
**          Can either provide data via @plexMembers or via channel-specific parameters
**
**          @plexMembers is a table listing Experiment ID values by channel or by tag
**          Supported header names: Channel, Tag, Tag_Name, Exp_ID, Experiment, Channel_Type, Comment
**
**          If the header row is missing from the table, will attempt to auto-determine the channel
**          The first two columns are required; Channel Type and Comment are optional
**
** Example 1:
**     Channel, Exp_ID, Channel Type, Comment
**     1, 212457, Normal,
**     2, 212458, Normal,
**     3, 212458, Normal,
**     4, 212459, Normal, Optionally define a comment
**     5, 212460, Normal,
**     6, 212461, Normal,
**     7, 212462, Normal,
**     8, 212463, Normal,
**     9, 212464, Normal,
**     10, 212465, Normal,
**     11, 212466, Reference, This is a pooled reference
**
**
** Example 2:
**     Tag, Exp_ID, Channel Type, Comment
**     126, 212457, Normal,
**     127N, 212458, Normal,
**     127C, 212458, Normal,
**     128N, 212459, Normal, Optionally define a comment
**     128C, 212460
**     129N, 212461
**     129C, 212462
**     130N, 212463, Normal,
**     130C, 212464, Normal,
**     131N, 212465
**     131C, 212466, Reference, This is a pooled reference
**
** Example 3:
**     Tag, Experiment, Channel Type, Comment
**     126, CPTAC_UCEC_Ref, Reference,
**     127N, CPTAC_UCEC_C3N-00858, Normal, Aliquot: CPT007832 0004
**     127C, CPTAC_UCEC_C3N-00858, Normal, Aliquot: CPT007836 0001
**     128N, CPTAC_UCEC_C3L-01252, Normal, Aliquot: CPT008062 0001
**     128C, CPTAC_UCEC_C3L-01252, Normal, Aliquot: CPT008061 0003
**     129N, CPTAC_UCEC_C3L-00947, Normal, Aliquot: CPT002742 0003
**     129C, CPTAC_UCEC_C3L-00947, Normal, Aliquot: CPT002743 0001
**     130N, CPTAC_UCEC_C3N-00734, Normal, Aliquot: CPT002603 0004
**     130C, CPTAC_UCEC_C3L-01248, Normal, Aliquot: CPT008030 0003
**     131, CPTAC_UCEC_C3N-00850, Normal, Aliquot: CPT002781 0003
**
**  Auth:   mem
**  Date:   11/19/2018 mem - Initial version
**          11/28/2018 mem - Allow the second column in the plex table to have experiment names instead of IDs
**                         - Make @expIdChannel and @channelType parameters optional
**                         - Add @comment parameters
**          11/29/2018 mem - Call alter_entered_by_user
**          11/30/2018 mem - Make @plexExperimentId an output parameter
**          09/04/2019 mem - If the plex experiment is a parent experiment of an experiment group, copy plex info to the members (fractions) of the experiment group
**          09/06/2019 mem - When updating a plex experiment that is a parent experiment of an experiment group, also update the members (fractions) of the experiment group
**          03/02/2020 mem - Update to support TMT 16 by adding channels 12-16
**          08/04/2021 mem - Rename @plexExperimentId to @plexExperimentIdOrName
**          11/09/2021 mem - Update @mode to support 'preview'
**          04/18/2022 mem - Update to support TMT 18 by adding channels 17 and 18
**          04/20/2022 mem - Fix typo in variable names
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @plexExperimentIdOrName varchar(130) output, -- Input/output parameter; used by the experiment_plex_members page family when copying an entry and changing the plex Exp_ID.  Accepts name or ID as input, but the output is always ID
    @plexMembers varchar(4000),                  -- Table of Channel to Exp_ID mapping (see above for examples)
    @expIdChannel1 varchar(130)='',              -- Experiment ID or Experiment Name or ExperimentID:ExperimentName
    @expIdChannel2 varchar(130)='',
    @expIdChannel3 varchar(130)='',
    @expIdChannel4 varchar(130)='',
    @expIdChannel5 varchar(130)='',
    @expIdChannel6 varchar(130)='',
    @expIdChannel7 varchar(130)='',
    @expIdChannel8 varchar(130)='',
    @expIdChannel9 varchar(130)='',
    @expIdChannel10 varchar(130)='',
    @expIdChannel11 varchar(130)='',
    @expIdChannel12 varchar(130)='',
    @expIdChannel13 varchar(130)='',
    @expIdChannel14 varchar(130)='',
    @expIdChannel15 varchar(130)='',
    @expIdChannel16 varchar(130)='',
    @expIdChannel17 varchar(130)='',
    @expIdChannel18 varchar(130)='',
    @channelType1 varchar(64)='',       -- Normal, Reference, or Empty
    @channelType2 varchar(64)='',
    @channelType3 varchar(64)='',
    @channelType4 varchar(64)='',
    @channelType5 varchar(64)='',
    @channelType6 varchar(64)='',
    @channelType7 varchar(64)='',
    @channelType8 varchar(64)='',
    @channelType9 varchar(64)='',
    @channelType10 varchar(64)='',
    @channelType11 varchar(64)='',
    @channelType12 varchar(64)='',
    @channelType13 varchar(64)='',
    @channelType14 varchar(64)='',
    @channelType15 varchar(64)='',
    @channelType16 varchar(64)='',
    @channelType17 varchar(64)='',
    @channelType18 varchar(64)='',
    @comment1 varchar(512)='',
    @comment2 varchar(512)='',
    @comment3 varchar(512)='',
    @comment4 varchar(512)='',
    @comment5 varchar(512)='',
    @comment6 varchar(512)='',
    @comment7 varchar(512)='',
    @comment8 varchar(512)='',
    @comment9 varchar(512)='',
    @comment10 varchar(512)='',
    @comment11 varchar(512)='',
    @comment12 varchar(512)='',
    @comment13 varchar(512)='',
    @comment14 varchar(512)='',
    @comment15 varchar(512)='',
    @comment16 varchar(512)='',
    @comment17 varchar(512)='',
    @comment18 varchar(512)='',
    @mode varchar(12) = 'add',      -- 'add', 'update', 'check_add', 'check_update', or 'preview'
    @message varchar(512) output,
    @callingUser varchar(128) = ''
)
AS
    Set XACT_ABORT, nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Set @message = ''

    Declare @msg varchar(256)
    Declare @logErrors tinyint = 0

    Declare @plexExperimentId int

    Declare @experimentLabel varchar(64)
    Declare @expectedChannelCount tinyint = 0
    Declare @actualChannelCount int = 0

    Declare @entryID int
    Declare @continue tinyint
    Declare @parseColData tinyint
    Declare @value varchar(2048)

    Declare @charIndex int

    Declare @plexExperimentName varchar(128) = ''

    Declare @currentPlexExperimentId Int
    Declare @targetPlexExperimentCount int = 0
    Declare @targetAddCount int = 0
    Declare @targetUpdateCount int = 0

    Declare @updatedRows int
    Declare @actionMessage varchar(128)
    Declare @experimentIdList Varchar(512) = ''

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = verify_sp_authorized 'add_update_experiment_plex_members', @raiseError = 1
    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;

    BEGIN TRY

    ---------------------------------------------------
    -- Validate input fields
    ---------------------------------------------------

    -- Set @compoundName = LTrim(RTrim(IsNull(@compoundName, '')))

    If @plexExperimentIdOrName Is Null
    Begin
        RAISERROR ('plexExperimentIdOrName cannot be null', 11, 118)
    End

    Set @plexExperimentId = Try_Cast(@plexExperimentIdOrName As int)

    If @plexExperimentId Is Null
    Begin
        -- Assume @plexExperimentIdOrName is an experiment name
        SELECT @plexExperimentId = Exp_ID
        FROM T_Experiments
        WHERE Experiment_Num = @plexExperimentIdOrName
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @myRowCount = 0
        Begin
            Set @message = 'Invalid Experiment Name: ' + @plexExperimentIdOrName
            RAISERROR (@message, 11, 118)
        End
    End

    -- Assure that @plexExperimentIdOrName has Experiment ID
    Set @plexExperimentIdOrName = Cast(@plexExperimentId As varchar(12))

    Set @plexMembers = IsNull(@plexMembers, '')

    Set @mode = IsNull(@mode, 'check_add')

    Set @callingUser = IsNull(@callingUser, '')

    Set @myError = 0

    ---------------------------------------------------
    -- Lookup the label associated with @plexExperimentId
    ---------------------------------------------------

    Set @experimentLabel = ''

    SELECT @experimentLabel = Ltrim(Rtrim(EX_Labelling))
    FROM T_Experiments
    WHERE Exp_ID = @plexExperimentId
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myRowCount = 0
    Begin
        Set @message = 'Invalid Plex Experiment ID ' + @plexExperimentIdOrName
        RAISERROR (@message, 11, 118)
    End

    If @experimentLabel In ('Unknown', 'None')
    Begin
        Set @message = 'Plex Experiment ID ' + @plexExperimentIdOrName + ' needs to have its isobaric label properly defined (as TMT10, TMT11, iTRAQ, etc.); it is currently ' + @experimentLabel
        RAISERROR (@message, 11, 118)
    End

    SELECT @expectedChannelCount = Count(*)
    FROM T_Sample_Labelling_Reporter_Ions
    WHERE Label = @experimentLabel
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    ---------------------------------------------------
    -- Create a temporary table to track the mapping info
    ---------------------------------------------------

    CREATE TABLE #TmpExperiment_Plex_Members (
        [Channel] [tinyint] NOT NULL,
        [Exp_ID] [int] NOT NULL,
        [Channel_Type_ID] [tinyint] NOT NULL,
        [Comment] [varchar](512) Null,
        [ValidExperiment] tinyint Not Null
    )

    Create Unique Clustered Index #IX_TmpExperiment_Plex_Members On #TmpExperiment_Plex_Members ([Channel])

    CREATE TABLE #TmpDatabaseUpdates (
        ID int IDENTITY (1,1) NOT NULL,
        Message varchar(128) NOT NULL
    )

    Create Unique Clustered Index #IX_TmpDatabaseUpdates On #TmpDatabaseUpdates (ID)

    ---------------------------------------------------
    -- Parse @plexMembers
    ---------------------------------------------------

    If Len(@plexMembers) > 0
    Begin -- <ParsePlexMembers>
        -- Split @plexMembers on newline characters

        Create Table #TmpRowData (Entry_ID int, [Value] varchar(2048))

        Create Table #TmpColData (Entry_ID int, [Value] varchar(2048))

        Declare @firstLineParsed tinyint = 0
        Declare @headersDefined tinyint = 0

        Declare @channelColNum tinyint = 0
        Declare @tagColNum tinyint = 0
        Declare @experimentIdColNum tinyint = 0
        Declare @channelTypeColNum tinyint = 0
        Declare @commentColNum tinyint = 0

        Declare @channelNum tinyint
        Declare @channelText varchar(32)
        Declare @tagName varchar(32)
        Declare @experimentId int
        Declare @experimentIdOrName varchar(128)
        Declare @channelTypeId int
        Declare @channelTypeName varchar(32)
        Declare @plexMemberComment varchar(512)

        INSERT INTO #TmpRowData( Entry_ID, [Value])
        SELECT EntryID, [Value]
        FROM dbo.parse_delimited_list_ordered(@plexMembers, char(10), 0)
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        Set @entryID = 0
        Set @continue = 1

        While @continue = 1
        Begin -- <WhileLoop>
            SELECT TOP 1 @entryID = Entry_ID,
                         @value = [Value]
            FROM #TmpRowData
            WHERE Entry_ID > @entryID
            ORDER BY Entry_ID
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            If @myRowCount = 0
            Begin
                Set @continue = 0
            End
            Else
            Begin -- <ItemFound>

                DELETE FROM #TmpColData

                -- Note that parse_delimited_list_ordered will replace tabs with commas

                INSERT INTO #TmpColData( Entry_ID, [Value])
                SELECT EntryID, [Value]
                FROM dbo.parse_delimited_list_ordered (@value, ',', 4)
                --
                SELECT @myError = @@error, @myRowCount = @@rowcount

                If @myRowCount > 0
                    Set @parseColData = 1
                Else
                    Set @parseColData = 0

                If @parseColData > 0 And @firstLineParsed = 0
                Begin -- <ParseHeaders>

                    SELECT Top 1 @channelColNum = Entry_ID
                    FROM #TmpColData
                    WHERE [Value] In ('Channel', 'Channel Number')
                    Order By Entry_ID
                    --
                    SELECT @myError = @@error, @myRowCount = @@rowcount

                    If @myRowCount > 0
                        Set @headersDefined = 1
                    Else
                    Begin
                        SELECT Top 1 @tagColNum = Entry_ID
                        FROM #TmpColData
                        WHERE [Value] In ('Tag', 'Tag_Name', 'Tag Name', 'Masic_Name', 'Masic Name')
                        Order By Entry_ID
                        --
                        SELECT @myError = @@error, @myRowCount = @@rowcount

                        If @myRowCount > 0
                            Set @headersDefined = 1
                    End

                    SELECT Top 1 @experimentIdColNum = Entry_ID
                    FROM #TmpColData
                    WHERE [Value] In ('Exp_ID', 'Exp ID', 'Experiment_ID', 'Experiment ID', 'Experiment', 'Exp_ID_or_Name', 'Name')
                    Order By Entry_ID
                    --
                    SELECT @myError = @@error, @myRowCount = @@rowcount

                    If @myRowCount > 0
                        Set @headersDefined = 1

                    SELECT Top 1 @channelTypeColNum = Entry_ID
                    FROM #TmpColData
                    WHERE [Value] In ('Channel_Type', 'Channel Type')
                    Order By Entry_ID
                    --
                    SELECT @myError = @@error, @myRowCount = @@rowcount

                    If @myRowCount > 0
                        Set @headersDefined = 1

                    SELECT Top 1 @commentColNum = Entry_ID
                    FROM #TmpColData
                    WHERE [Value] Like 'Comment%'
                    Order By Entry_ID
                    --
                    SELECT @myError = @@error, @myRowCount = @@rowcount

                    If @myRowCount > 0
                        Set @headersDefined = 1

                    If @headersDefined > 0
                    Begin
                        If @channelColNum = 0 And @tagColNum = 0
                        Begin
                            RAISERROR ('Plex Members table must have column header Channel or Tag', 11, 118)
                        End

                        If @experimentIdColNum = 0
                        Begin
                            RAISERROR ('Plex Members table must have column header Exp_ID or Experiment', 11, 118)
                        End

                        DELETE FROM #TmpColData
                    End
                    Else
                    Begin
                        RAISERROR ('Plex Members table must start with a row of header names, for example: Tag, Exp_ID, Channel Type, Comment', 11, 118)
                    End

                    Set @firstLineParsed = 1
                    Set @parseColData = 0
                End -- </ParseHeaders>

                If @parseColData > 0
                Begin -- <ParseColData>

                    Set @channelNum = 0
                    Set @channelText = ''
                    Set @tagName = ''
                    Set @experimentId = 0
                    Set @experimentIdOrName = ''
                    Set @channelTypeId = 0
                    Set @channelTypeName = ''
                    Set @plexMemberComment = ''

                    If @channelColNum > 0
                    Begin
                        SELECT @channelText = Value
                        FROM #TmpColData
                        WHERE Entry_ID = @channelColNum
                    End

                    If @tagColNum > 0
                    Begin
                        SELECT @tagName = Value
                        FROM #TmpColData
                        WHERE Entry_ID = @tagColNum
                    End

                    SELECT @experimentIdOrName = [Value]
                    FROM #TmpColData
                    WHERE Entry_ID = @experimentIdColNum

                    If @channelTypeColNum > 0
                    Begin
                        SELECT @channelTypeName = [Value]
                        FROM #TmpColData
                        WHERE Entry_ID = @channelTypeColNum
                    End

                    If @commentColNum > 0
                    Begin
                        SELECT @plexMemberComment = [Value]
                        FROM #TmpColData
                        WHERE Entry_ID = @commentColNum
                    End

                    If Len(@channelText) > 0
                    Begin -- <ChannelNum>
                        Set @channelNum = Try_Cast(@channelText As tinyint)

                        If @channelNum Is Null
                        Begin
                            Set @message = 'Could not convert channel number ' + @channelText + ' to an integer in row ' + Cast(@entryID As varchar(12)) + ' of the Plex Members table'
                            RAISERROR (@message, 11, 118)
                        End
                    End -- </ChannelNum>
                    Else
                    Begin -- <TagName>
                        If Len(@tagName) > 0
                        Begin
                            If @experimentLabel = 'TMT10' And @tagName = '131'
                            Begin
                                Set @tagName = '131N'
                            End

                            Set @channelNum = Null

                            SELECT Top 1 @channelNum = Channel
                            FROM T_Sample_Labelling_Reporter_Ions
                            WHERE Label = @experimentLabel And (Tag_Name = @tagName Or [MASIC_Name] = @tagName)
                            --
                            SELECT @myError = @@error, @myRowCount = @@rowcount

                            If @myRowCount = 0
                            Begin
                                Set @message = 'Could not determine the channel number for tag ' + @tagName + ' and label ' + @experimentLabel + '; see https://dms2.pnl.gov/sample_label_reporter_ions/report/' + @experimentLabel
                                RAISERROR (@message, 11, 118)
                            End
                        End
                    End -- </TagName>

                    Set @experimentId = Try_Cast(@experimentIdOrName As integer)

                    If @experimentId Is Null
                    Begin
                        -- Not an integer; is it a valid experiment name?
                        SELECT @experimentId = Exp_ID
                        FROM T_Experiments
                        WHERE Experiment_Num = @experimentIdOrName
                        --
                        SELECT @myError = @@error, @myRowCount = @@rowcount

                        If @myRowCount = 0
                        Begin
                            If @tagName = ''
                                Set @message = 'Experiment not found for channel ' + Cast(@channelNum As varchar(12))
                            Else
                                Set @message = 'Experiment not found for tag ' + @tagName

                            Set @message = @message + ' (specify an experiment ID or name): ' + @experimentIdOrName +
                                                      ' (see row ' + Cast(@entryID As varchar(12)) + ' of the Plex Members table)'
                            RAISERROR (@message, 11, 118)
                        End
                    End

                    If Len(@channelTypeName) > 0
                    Begin -- <ChannelTypeDefined>
                        SELECT @channelTypeId = Channel_Type_ID
                        FROM T_Experiment_Plex_Channel_Type_Name
                        WHERE Channel_Type_Name = @channelTypeName
                        --
                        SELECT @myError = @@error, @myRowCount = @@rowcount

                        If @myRowCount = 0
                        Begin
                            Set @message = 'Invalid channel type ' + @channelTypeName + ' in row ' + Cast(@entryID As varchar(12)) + ' of the Plex Members table; valid values: '

                            SELECT @message = @message + Channel_Type_Name + ', '
                            FROM T_Experiment_Plex_Channel_Type_Name

                            Set @message = Substring(@message, 1, Len(@message) - 1)
                            RAISERROR (@message, 11, 118)
                        End
                    End -- </ChannelTypeDefined>
                    Else
                    Begin
                        -- Default to type "Normal"
                        Set @channelTypeId = 1
                    End

                    If IsNull(@channelNum, 0) > 0 And IsNull(@experimentId, 0) > 0
                    Begin
                        If Exists (SELECT * FROM #TmpExperiment_Plex_Members WHERE Channel = @channelNum)
                        Begin
                            Set @message = 'Plex Members table has duplicate entries for channel ' + Cast(@channelNum As varchar(12))
                            If @tagName <> ''
                            Begin
                                Set @message = @message + ' (tag ' + @tagName + ')'
                            End

                            RAISERROR (@message, 11, 118)
                        End
                        Else
                        Begin
                            Insert Into #TmpExperiment_Plex_Members (Channel, Exp_ID, Channel_Type_ID, Comment, ValidExperiment)
                            Values (@channelNum, @experimentId, @channelTypeId, @plexMemberComment, 0)
                        End
                    End

                End -- </ParseColData>

            End -- </ItemFound>
        End  -- </WhileLoop>
    End -- <ParsePlexMembers>

    ---------------------------------------------------
    -- Check whether we even need to parse the individual parameters
    ---------------------------------------------------

    SELECT @actualChannelCount = Count(*)
    FROM #TmpExperiment_Plex_Members
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If IsNull(@expectedChannelCount, 0) = 0 Or @actualChannelCount < @expectedChannelCount
    Begin
        -- Step through the @expIdChannel and @channelType fields to define info for channels not defined in the Plex Members table

        CREATE TABLE #TmpExperiment_Plex_Members_From_Params (
            [Channel] [tinyint] NOT NULL,
            [ExperimentInfo] varchar(130) NULL,
            [ChannelType] varchar(64) NULL,
            [Comment] varchar(512) NULL
        )

        Insert Into #TmpExperiment_Plex_Members_From_Params Values (1,  @expIdChannel1,  @channelType1,  @comment1)
        Insert Into #TmpExperiment_Plex_Members_From_Params Values (2,  @expIdChannel2,  @channelType2,  @comment2)
        Insert Into #TmpExperiment_Plex_Members_From_Params Values (3,  @expIdChannel3,  @channelType3,  @comment3)
        Insert Into #TmpExperiment_Plex_Members_From_Params Values (4,  @expIdChannel4,  @channelType4,  @comment4)
        Insert Into #TmpExperiment_Plex_Members_From_Params Values (5,  @expIdChannel5,  @channelType5,  @comment5)
        Insert Into #TmpExperiment_Plex_Members_From_Params Values (6,  @expIdChannel6,  @channelType6,  @comment6)
        Insert Into #TmpExperiment_Plex_Members_From_Params Values (7,  @expIdChannel7,  @channelType7,  @comment7)
        Insert Into #TmpExperiment_Plex_Members_From_Params Values (8,  @expIdChannel8,  @channelType8,  @comment8)
        Insert Into #TmpExperiment_Plex_Members_From_Params Values (9,  @expIdChannel9,  @channelType9,  @comment9)
        Insert Into #TmpExperiment_Plex_Members_From_Params Values (10, @expIdChannel10, @channelType10, @comment10)
        Insert Into #TmpExperiment_Plex_Members_From_Params Values (11, @expIdChannel11, @channelType11, @comment11)
        Insert Into #TmpExperiment_Plex_Members_From_Params Values (12, @expIdChannel12, @channelType12, @comment12)
        Insert Into #TmpExperiment_Plex_Members_From_Params Values (13, @expIdChannel13, @channelType13, @comment13)
        Insert Into #TmpExperiment_Plex_Members_From_Params Values (14, @expIdChannel14, @channelType14, @comment14)
        Insert Into #TmpExperiment_Plex_Members_From_Params Values (15, @expIdChannel15, @channelType15, @comment15)
        Insert Into #TmpExperiment_Plex_Members_From_Params Values (16, @expIdChannel16, @channelType16, @comment16)
        Insert Into #TmpExperiment_Plex_Members_From_Params Values (17, @expIdChannel17, @channelType17, @comment17)
        Insert Into #TmpExperiment_Plex_Members_From_Params Values (18, @expIdChannel18, @channelType18, @comment18)

        Set @channelNum = 1
        While @channelNum <= 18
        Begin
            If Not Exists (SELECT * FROM #TmpExperiment_Plex_Members WHERE [Channel] = @channelNum)
            Begin -- <ProcessChannelParam>
                SELECT @experimentIdOrName = LTrim(RTrim(IsNull(ExperimentInfo, ''))),
                       @channelTypeName = Ltrim(RTrim(IsNull(ChannelType, ''))),
                       @plexMemberComment = Ltrim(RTrim(IsNull(Comment, '')))
                FROM #TmpExperiment_Plex_Members_From_Params
                WHERE [Channel] = @channelNum
                --
                SELECT @myError = @@error, @myRowCount = @@rowcount

                Set @experimentId = 0

                If Len(@experimentIdOrName) > 0
                Begin -- <ExperimentIdDefined>

                    -- ExperimentIdText can have Experiment ID, or Experiment Name, or both, separated by a colon, comma, space, or tab
                    -- First assure that the delimiter (if present) is a colon
                    Set @experimentIdOrName = Replace(@experimentIdOrName, ',', ':')
                    Set @experimentIdOrName = Replace(@experimentIdOrName, char(9), ':')
                    Set @experimentIdOrName = Replace(@experimentIdOrName, ' ', ':')

                    -- Look for a colon
                    Set @charIndex = CharIndex(':', @experimentIdOrName)
                    If @charIndex > 1
                    Begin
                        Set @experimentId = Try_Cast(Substring(@experimentIdOrName, 1, @charIndex-1) As int)

                        If @experimentId Is Null
                        Begin
                            Set @message = 'Could not parse out the experiment ID from ' + Substring(@experimentIdOrName, 1, @charIndex-1) + ' for channel ' + Cast(@channelNum As varchar(12))
                            RAISERROR (@message, 11, 118)
                        End

                    End
                    Else
                    Begin
                        -- No colon (or the first character is a colon)
                        -- First try to match experiment ID
                        Set @experimentId = Try_Cast(@experimentIdOrName As int)

                        If @experimentId Is Null
                        Begin
                            -- No match; try to match experiment name
                            SELECT @experimentId = Exp_ID
                            FROM T_Experiments
                            WHERE Experiment_Num = @experimentIdOrName
                            --
                            SELECT @myError = @@error, @myRowCount = @@rowcount

                            If @myRowCount = 0
                            Begin
                                Set @message = 'Experiment not found for channel ' + Cast(@channelNum As varchar(12)) + ': ' + @experimentIdOrName
                                RAISERROR (@message, 11, 118)
                            End
                        End
                    End

                    If Len(@channelTypeName) = 0
                    Begin
                        Set @channelTypeId = 1
                    End
                    Else
                    Begin -- <ChannelTypeDefined>
                        SELECT @channelTypeId = Channel_Type_ID
                        FROM T_Experiment_Plex_Channel_Type_Name
                        WHERE Channel_Type_Name = @channelTypeName
                        --
                        SELECT @myError = @@error, @myRowCount = @@rowcount

                        If @myRowCount = 0
                        Begin
                            Set @message = 'Invalid channel type ' + @channelTypeName + ' for channel ' + Cast(@channelNum As varchar(12)) + '; valid values: '

                            SELECT @message = @message + Channel_Type_Name + ', '
                            FROM T_Experiment_Plex_Channel_Type_Name

                            Set @message = Substring(@message, 1, Len(@message) - 1)
                            RAISERROR (@message, 11, 118)
                        End
                    End -- </ChannelTypeDefined>

                    If IsNull(@experimentId, 0) > 0
                    Begin
                        Insert Into #TmpExperiment_Plex_Members (Channel, Exp_ID, Channel_Type_ID, Comment, ValidExperiment)
                        Values (@channelNum, @experimentId, @channelTypeId, @plexMemberComment, 0)
                    End

                End -- </ExperimentIdDefined>

            End -- </ProcessChannelParam>

            Set @channelNum = @channelNum + 1
        End
    End

    ---------------------------------------------------
    -- Update the cached actual chanel count
    ---------------------------------------------------

    SELECT @actualChannelCount = Count(*)
    FROM #TmpExperiment_Plex_Members

    ---------------------------------------------------
    -- Validate experiment IDs in #TmpExperiment_Plex_Members
    ---------------------------------------------------

    UPDATE #TmpExperiment_Plex_Members
    SET ValidExperiment = 1
    FROM #TmpExperiment_Plex_Members PlexMembers
         INNER JOIN T_Experiments E
           ON PlexMembers.Exp_ID = E.Exp_ID
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    Declare @invalidExperimentCount int = 0

    SELECT @invalidExperimentCount = Count(*)
    FROM #TmpExperiment_Plex_Members
    WHERE ValidExperiment = 0

    If IsNull(@invalidExperimentCount, 0) > 0
    Begin
        If @invalidExperimentCount = 1
        Begin
            SELECT @message = 'Invalid Experiment ID: ' +  Cast(Exp_ID As varchar(12))
            FROM #TmpExperiment_Plex_Members
            WHERE ValidExperiment = 0
        End
        Else
        Begin
            Set @message = 'Invalid Experiment IDs: '

            SELECT @message = @message + Cast(Exp_ID As varchar(12)) + ','
            FROM #TmpExperiment_Plex_Members
            WHERE ValidExperiment = 0

            Set @message= Substring(@message, 1, Len(@message) - 1)
        End

        RAISERROR (@message, 11, 118)
    End

    Set @logErrors = 1

    ---------------------------------------------------
    -- Action for add, update, or preview mode
    ---------------------------------------------------

    If @mode IN ('add', 'update', 'preview')
    Begin -- <AddOrUpdate>

        ---------------------------------------------------
        -- Create a temporary table to hold the experiment IDs that will be updated with the plex info in #TmpExperiment_Plex_Members
        ---------------------------------------------------

        CREATE TABLE #Tmp_ExperimentsToUpdate (plexExperimentId int Not Null)

        CREATE INDEX #IX_Tmp_ExperimentsToUpdate On #Tmp_ExperimentsToUpdate (plexExperimentId)

        INSERT INTO #Tmp_ExperimentsToUpdate (plexExperimentId )
        VALUES(@plexExperimentId)

        ---------------------------------------------------
        -- Check whether this experiment is the parent experiment of any experiment groups
        -- An experiment can be the parent experiment for more than one group, for example
        -- StudyName4_TB_Plex11 could be the parent experiment for group ID 6846, with members:
        --   StudyName4_TB_Plex11_G_f01
        --   StudyName4_TB_Plex11_G_f02
        --   StudyName4_TB_Plex11_G_f03
        --   StudyName4_TB_Plex11_G_f04
        -- and also the parent experiment for group ID 6847 with members:
        --   StudyName4_TB_Plex11_P_f01
        --   StudyName4_TB_Plex11_P_f02
        --   StudyName4_TB_Plex11_P_f03
        --   StudyName4_TB_Plex11_P_f04
        ---------------------------------------------------

        If Exists (SELECT * From T_Experiment_Groups WHERE Parent_Exp_ID = @plexExperimentId)
        Begin
            ---------------------------------------------------
            -- Add experiments that are associated with parent experiment @plexExperimentId
            -- Assure that the parent experiment is not the 'Placeholder' experiment
            ---------------------------------------------------
            --
            INSERT INTO #Tmp_ExperimentsToUpdate (plexExperimentId )
            SELECT DISTINCT EGM.Exp_ID
            FROM T_Experiment_Groups EG
                 INNER JOIN T_Experiment_Group_Members EGM
                   ON EGM.Group_ID = EG.Group_ID
                 INNER JOIN T_Experiments E
                   ON EG.Parent_Exp_ID = E.Exp_ID
            WHERE EG.Parent_Exp_ID = @plexExperimentId AND
                  E.Experiment_Num <> 'Placeholder'
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount
        End

        ---------------------------------------------------
        -- Process each experiment in #Tmp_ExperimentsToUpdate
        -- We're processing the experiments one at a time due to the use of the following condition for deleting extra rows:
        --   WHEN NOT MATCHED BY SOURCE And T.Plex_exp_id = @currentPlexExperimentId
        -- This method only works if comparing T.Plex_exp_id to a constant
        ---------------------------------------------------

        Set @currentPlexExperimentId = 0
        Set @continue = 1

        While @continue = 1
        Begin -- <WhileLoop>

            SELECT TOP 1 @currentPlexExperimentId = plexExperimentId
            FROM #Tmp_ExperimentsToUpdate
            WHERE plexExperimentId > @currentPlexExperimentId
            ORDER BY plexExperimentId
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            If @myRowCount = 0
            Begin
                Set @continue = 0
            End
            Else
            Begin
                If @experimentIdList = ''
                Begin
                    Set @experimentIdList = Cast(@currentPlexExperimentId As varchar(12))
                End
                Else
                Begin
                    Set @experimentIdList = @experimentIdList + ', ' + Cast(@currentPlexExperimentId As varchar(12))
                End

                If @mode = 'preview'
                Begin -- <PreviewAddUpdate>
                    Set @updatedRows = 0

                    SELECT @updatedRows = Count(*)
                    FROM T_Experiment_Plex_Members t
                         INNER JOIN #TmpExperiment_Plex_Members s
                           ON t.[Channel] = s.[Channel]
                    WHERE t.[Plex_Exp_ID] = @currentPlexExperimentId

                    If @updatedRows = @actualChannelCount
                    Begin
                        Set @actionMessage = 'Would update ' + Cast(@updatedRows As varchar(12)) + ' channels for Exp_ID ' + Cast(@currentPlexExperimentId As varchar(12))
                    End
                    Else If @updatedRows = 0
                    Begin
                        Set @actionMessage = 'Would add ' + Cast(@actualChannelCount As varchar(12)) + ' channels for Exp_ID ' + Cast(@currentPlexExperimentId As varchar(12))
                    End
                    Else
                    Begin
                        Set @actionMessage = 'Would add/update ' + Cast(@actualChannelCount As varchar(12)) + ' channels for Exp_ID ' + Cast(@currentPlexExperimentId As varchar(12))
                    End

                    Insert Into #TmpDatabaseUpdates (Message) Values (@actionMessage)

                End -- </PreviewAddUpdate>
                Else
                Begin  -- <AddUpdatePlexInfo>
                    MERGE [dbo].[T_Experiment_Plex_Members] AS t
                    USING (SELECT Channel, Exp_ID, Channel_Type_ID, [Comment]
                           FROM #TmpExperiment_Plex_Members) as s
                    ON ( t.[Channel] = s.[Channel] AND t.[Plex_Exp_ID] = @currentPlexExperimentId)
                    WHEN MATCHED AND (
                        t.[Exp_ID] <> s.[Exp_ID] OR
                        t.[Channel_Type_ID] <> s.[Channel_Type_ID] OR
                        ISNULL( NULLIF(t.[Comment], s.[Comment]),
                                NULLIF(s.[Comment], t.[Comment])) IS NOT NULL
                        )
                    THEN UPDATE SET
                        [Exp_ID] = s.[Exp_ID],
                        [Channel_Type_ID] = s.[Channel_Type_ID],
                        [Comment] = s.[Comment]
                    WHEN NOT MATCHED BY TARGET THEN
                        INSERT([Plex_Exp_ID], [Channel], [Exp_ID], [Channel_Type_ID], [Comment])
                        VALUES(@currentPlexExperimentId, s.[Channel], s.[Exp_ID], s.[Channel_Type_ID], s.[Comment])
                    WHEN NOT MATCHED BY SOURCE And T.Plex_exp_id = @currentPlexExperimentId THEN DELETE;
                    --
                    SELECT @myError = @@error, @myRowCount = @@rowcount
                    --
                    If @myError <> 0
                    Begin
                        Set @msg = 'Update operation failed: "' + @currentPlexExperimentId + '"'
                        RAISERROR (@msg, 11, 18)
                    End

                    If Len(@callingUser) > 0
                    Begin
                        -- Call alter_entered_by_user to alter the Entered_By field in T_Experiment_Plex_Members_History
                        --
                        Exec alter_entered_by_user 'T_Experiment_Plex_Members_History', 'Plex_Exp_ID', @currentPlexExperimentId, @CallingUser
                    End
                End  -- </AddUpdatePlexInfo>
            End

        End -- </WhileLoop>

        If @mode = 'add'
        Begin
            If @experimentIdList Like '%,%'
            Begin
                Set @message = 'Defined experiment plex members for Exp_IDs: ' + @experimentIdList
            End
            Else
            Begin
                Set @message = 'Defined experiment plex members for Plex Exp ID ' + @plexExperimentIdOrName
            End
        End
        Else If @mode = 'preview'
        Begin
            SELECT @targetPlexExperimentCount = Count(*)
            FROM #TmpDatabaseUpdates

            SELECT @targetAddCount = Count(*)
            FROM #TmpDatabaseUpdates
            WHERE Message Like 'Would add %'

            SELECT @targetUpdateCount = Count(*)
            FROM #TmpDatabaseUpdates
            WHERE Message like 'Would update %'

            SELECT TOP 1 @message = Message
            FROM #TmpDatabaseUpdates
            ORDER BY ID

            If @targetPlexExperimentCount > 1
            Begin

                If @targetAddCount = @targetPlexExperimentCount
                Begin
                    -- Adding plex members for all of the target experiments
                    Set @message = 'Would add ' + Cast(@actualChannelCount As varchar(12)) + ' channels for Exp_IDs: ' + @experimentIdList
                End
                Else If @targetUpdateCount = @targetPlexExperimentCount
                Begin
                    -- Updating plex members for all of the target experiments
                    Set @message = 'Would update ' + Cast(@updatedRows As varchar(12)) + ' channels for Exp_IDs: ' + @experimentIdList
                End
                Else
                Begin
                    -- Mix of adding and updating plex members

                    -- Append the message for the next 6 experiments

                    Set @entryId = 2
                    While @entryID <= @targetPlexExperimentCount And @entryID <= 7
                    Begin
                        SELECT @msg = Message
                        FROM #TmpDatabaseUpdates
                        WHERE ID = @entryID

                        Set @message = @message + ', ' + Replace(@msg, 'Would', 'would')

                        Set @entryID = @entryID + 1
                    End

                    If @targetPlexExperimentCount > 7
                    Begin
                        SELECT TOP 1 @msg = Message
                        FROM #TmpDatabaseUpdates
                        ORDER BY ID DESC

                        Set @message = @message + ' ... ' + Replace(@msg, 'Would', 'would')
                    End
                End
            End
        End

    End -- </AddOrUpdate>

    End TRY
    Begin CATCH
        EXEC format_error_message @message output, @myError output

        -- Rollback any open transactions
        If (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;

        If @logErrors > 0
        Begin
            Declare @logMessage varchar(1024) = @message + '; Plex Exp ID ' + @plexExperimentIdOrName
            exec post_log_entry 'Error', @logMessage, 'add_update_experiment_plex_members'
        End

    End CATCH

    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[add_update_experiment_plex_members] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[add_update_experiment_plex_members] TO [DMS_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[add_update_experiment_plex_members] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[add_update_experiment_plex_members] TO [Limited_Table_Write] AS [dbo]
GO
