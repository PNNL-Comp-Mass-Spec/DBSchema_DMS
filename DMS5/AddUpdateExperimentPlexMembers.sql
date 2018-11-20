/****** Object:  StoredProcedure [dbo].[AddUpdateExperimentPlexMembers] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure [dbo].[AddUpdateExperimentPlexMembers]
/****************************************************
**
**	Desc:   Adds new or updates existing rows in T_Experiment_Plex_Members
**          Can either provide data via @plexMembers or via channel-specific parameters
**
**          @plexMembers is a table listing Experiment ID values by channel or by tag
**          Supported header names: Channel, Tag, Tag_Name, Exp_ID, Channel_Type, Comment
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
**	Auth:	mem
**	Date:	11/19/2018 mem - Initial version
**    
*****************************************************/
(
	@plexExperimentId int,
    @plexMembers varchar(4000),         -- Table of Channel to Exp_ID mapping (see above for examples)
    @expIdChannel1 varchar(130),        -- Experiment ID; can optionally also have the experiment name
    @expIdChannel2 varchar(130),
    @expIdChannel3 varchar(130),
    @expIdChannel4 varchar(130),
    @expIdChannel5 varchar(130),
    @expIdChannel6 varchar(130),
    @expIdChannel7 varchar(130),
    @expIdChannel8 varchar(130),
    @expIdChannel9 varchar(130),
    @expIdChannel10 varchar(130),
    @expIdChannel11 varchar(130),
    @channelType1 varchar(64),
    @channelType2 varchar(64),
    @channelType3 varchar(64),
    @channelType4 varchar(64),
    @channelType5 varchar(64),
    @channelType6 varchar(64),
    @channelType7 varchar(64),
    @channelType8 varchar(64),
    @channelType9 varchar(64),
    @channelType10 varchar(64),
    @channelType11 varchar(64),
	@mode varchar(12) = 'add',		-- 'add', 'update', 'check_add', 'check_update'
	@message varchar(512) output,
	@callingUser varchar(128) = ''		
)
As
	Set XACT_ABORT, nocount on

	Declare @myError int = 0
	Declare @myRowCount int = 0
	
	Set @message = ''

	Declare @msg varchar(256)
	Declare @logErrors tinyint = 0

    Declare @plexExperimentIdText varchar(12) = Cast(@plexExperimentId As varchar(12))

    Declare @experimentLabel varchar(64)
    Declare @expectedChannelCount tinyint = 0
    Declare @actualChannelCount int = 0

    Declare @entryID int
    Declare @continue tinyint
    Declare @parseColData tinyint
    Declare @value varchar(2048)
	
    Declare @charIndex int

	---------------------------------------------------
	-- Verify that the user can execute this procedure from the given client host
	---------------------------------------------------
		
	Declare @authorized tinyint = 0	
	Exec @authorized = VerifySPAuthorized 'AddUpdateExperimentPlexMembers', @raiseError = 1
	If @authorized = 0
	Begin;
		THROW 51000, 'Access denied', 1;
	End;

	BEGIN TRY 

	---------------------------------------------------
	-- Validate input fields
	---------------------------------------------------

	-- Set @compoundName = LTrim(RTrim(IsNull(@compoundName, '')))	

    If @plexExperimentId Is Null
    Begin
        RAISERROR ('plexExperimentId cannot be null', 11, 118)
    End

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
        Set @message = 'Invalid Plex Experiment ID ' + @plexExperimentIdText
        RAISERROR (@message, 11, 118)
    End

    If @experimentLabel In ('Unknown', 'None')
    Begin
        Set @message = 'Plex Experiment ID ' + @plexExperimentIdText + ' needs to have its isobaric label properly defined; it is currently ' + @experimentLabel
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
        Declare @experimentIdText varchar(32)
        Declare @channelTypeId int
        Declare @channelTypeName varchar(32)
        Declare @plexMemberComment varchar(32)

        INSERT INTO #TmpRowData( Entry_ID, [Value])
        SELECT EntryID, [Value]
        FROM dbo.udfParseDelimitedListOrdered(@plexMembers, char(10), 0)
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

                Delete From #TmpColData

                -- Note that udfParseDelimitedListOrdered will replace tabs with commas

                INSERT INTO #TmpColData( Entry_ID, [Value])
                SELECT EntryID, [Value]
                FROM dbo.udfParseDelimitedListOrdered (@value, ',', 4)
                --
                SELECT @myError = @@error, @myRowCount = @@rowcount

                If @myRowCount > 0
                    Set @parseColData = 1
                Else
                    Set @parseColData = 0

                If @parseColData > 0 And @firstLineParsed = 0
                Begin -- <ParseHeaders>

                    Select Top 1 @channelColNum = Entry_ID
                    From #TmpColData
                    Where [Value] In ('Channel', 'Channel Number')
                    Order By Entry_ID
                    --
                    SELECT @myError = @@error, @myRowCount = @@rowcount

                    If @myRowCount > 0
                        Set @headersDefined = 1
                    Else
                    Begin
                        Select Top 1 @tagColNum = Entry_ID
                        From #TmpColData
                        Where [Value] In ('Tag', 'Tag_Name', 'Tag Name', 'Masic_Name', 'Masic Name')
                        Order By Entry_ID
                        --
                        SELECT @myError = @@error, @myRowCount = @@rowcount

                        If @myRowCount > 0
                            Set @headersDefined = 1
                    End

                    Select Top 1 @experimentIdColNum = Entry_ID
                    From #TmpColData
                    Where [Value] In ('Exp_ID', 'Exp ID', 'Experiment_ID', 'Experiment ID', 'Experiment')
                    Order By Entry_ID
                    --
                    SELECT @myError = @@error, @myRowCount = @@rowcount

                    If @myRowCount > 0
                        Set @headersDefined = 1

                    Select Top 1 @channelTypeColNum = Entry_ID
                    From #TmpColData
                    Where [Value] In ('Channel_Type', 'Channel Type')
                    Order By Entry_ID
                    --
                    SELECT @myError = @@error, @myRowCount = @@rowcount

                    If @myRowCount > 0
                        Set @headersDefined = 1

                    Select Top 1 @commentColNum = Entry_ID
                    From #TmpColData
                    Where [Value] Like 'Comment%'
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
                            RAISERROR ('Plex Members table must have column header Exp_ID', 11, 118)
                        End

                        Delete From #TmpColData
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
                    Set @experimentIdText = ''
                    Set @channelTypeId = 0
                    Set @channelTypeName = ''
                    Set @plexMemberComment = ''

                    If @channelColNum > 0
                    Begin
                        Select @channelText = Value
                        From #TmpColData
                        Where Entry_ID = @channelColNum
                    End

                    If @tagColNum > 0
                    Begin
                        Select @tagName = Value
                        From #TmpColData
                        Where Entry_ID = @tagColNum
                    End

                    Select @experimentIdText = Value
                    From #TmpColData
                    Where Entry_ID = @experimentIdColNum

                    If @channelTypeColNum > 0
                    Begin
                        Select @channelTypeName = Value
                        From #TmpColData
                        Where Entry_ID = @channelTypeColNum
                    End

                    If @commentColNum > 0
                    Begin
                        Select @plexMemberComment = Value
                        From #TmpColData
                        Where Entry_ID = @commentColNum
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
                            Set @channelNum = Null

                            SELECT Top 1 @channelNum = Channel      
                            FROM T_Sample_Labelling_Reporter_Ions
                            Where Label = @experimentLabel And (Tag_Name = @tagName Or [MASIC_Name] = @tagName)
                            --
                            SELECT @myError = @@error, @myRowCount = @@rowcount

                            If @myRowCount = 0
                            Begin
                                SELECT Top 1 @channelNum = Channel      
                                FROM T_Sample_Labelling_Reporter_Ions
                                Where Tag_Name = @tagName Or [MASIC_Name] = @tagName
                                --
                                SELECT @myError = @@error, @myRowCount = @@rowcount
                            End

                            If @myRowCount = 0
                            Begin
                                Set @message = 'Could not determine the channel number for tag ' + @tagName + '; see https://dms2.pnl.gov/sample_label_reporter_ions/report'
                            End
                        End
                    End -- </TagName>

                    Set @experimentId = Try_Cast(@experimentIdText As integer)
                  
                    If @experimentId Is Null
                    Begin
                        Set @message = 'Could not convert Experiment ID ' + @experimentIdText + ' to an integer in row ' + Cast(@entryID As varchar(12)) + ' of the Plex Members table'
                        RAISERROR (@message, 11, 118)
                    End

                    If Len(@channelTypeName) > 0
                    Begin -- <ChannelTypeDefined>
                        SELECT @channelTypeId = Channel_Type_ID
                        FROM T_Experiment_Plex_Channel_Type_Name
                        Where Channel_Type_Name = @channelTypeName
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
                        If Exists (Select * From #TmpExperiment_Plex_Members Where Channel = @channelNum)
                        Begin
                            Set @message = 'Plex Members table has duplicate entries for channel ' + Cast(@channelNum As varchar(12))
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
            [ChannelType] varchar(64) NULL
	    )
        
        Insert Into #TmpExperiment_Plex_Members_From_Params Values (1,  @expIdChannel1,  @channelType1)
        Insert Into #TmpExperiment_Plex_Members_From_Params Values (2,  @expIdChannel2,  @channelType2)
        Insert Into #TmpExperiment_Plex_Members_From_Params Values (3,  @expIdChannel3,  @channelType3)
        Insert Into #TmpExperiment_Plex_Members_From_Params Values (4,  @expIdChannel4,  @channelType4)
        Insert Into #TmpExperiment_Plex_Members_From_Params Values (5,  @expIdChannel5,  @channelType5)
        Insert Into #TmpExperiment_Plex_Members_From_Params Values (6,  @expIdChannel6,  @channelType6)
        Insert Into #TmpExperiment_Plex_Members_From_Params Values (7,  @expIdChannel7,  @channelType7)
        Insert Into #TmpExperiment_Plex_Members_From_Params Values (8,  @expIdChannel8,  @channelType8)
        Insert Into #TmpExperiment_Plex_Members_From_Params Values (9,  @expIdChannel9,  @channelType9)
        Insert Into #TmpExperiment_Plex_Members_From_Params Values (10, @expIdChannel10, @channelType10)
        Insert Into #TmpExperiment_Plex_Members_From_Params Values (11, @expIdChannel11, @channelType11)

        Set @channelNum = 1
        While @channelNum <= 11
        Begin
            If Not Exists (Select * From #TmpExperiment_Plex_Members Where [Channel] = @channelNum)
            Begin -- <ProcessChannelParam>
                SELECT @experimentIdText = LTrim(RTrim(IsNull(ExperimentInfo, ''))),
                       @channelTypeName = Ltrim(RTrim(IsNull(ChannelType, '')))
                FROM #TmpExperiment_Plex_Members_From_Params
                WHERE [Channel] = @channelNum
                --
                SELECT @myError = @@error, @myRowCount = @@rowcount

                Set @experimentId = 0

                If Len(@experimentIdText) > 0
                Begin -- <ExperimentIdDefined>

                    -- ExerimentIdText can have Experiment ID, or Experiment Name, or both, separated by a colon, comma, space, or tab
                    Set @experimentIdText = Replace(@experimentIdText, ',', ':')
                    Set @experimentIdText = Replace(@experimentIdText, char(9), ':')
                    Set @experimentIdText = Replace(@experimentIdText, ' ', ':')

                    Set @charIndex = CharIndex(':', @experimentIdText)
                    If @charIndex > 1
                    Begin
                        Set @experimentId = Try_Cast(Substring(@experimentIdText, 1, @charIndex-1) As int)

                        If @experimentId Is Null
                        Begin
                            Set @message = 'Could not parse out the experiment ID from ' + Substring(@experimentIdText, 1, @charIndex-1) + ' for channel ' + Cast(@channelNum As varchar(12))
                            RAISERROR (@message, 11, 118)
                        End

                    End
                    Else
                    Begin
                        -- No colon (or the first character is a colon)
                        -- First try to match experiment ID
                        Set @experimentId = Try_Cast(@experimentIdText As int)
                    
                        If @experimentId Is Null
                        Begin
                            -- No match; try to match experiment name
                            SELECT @experimentId = Exp_ID
                            FROM T_Experiments
                            WHERE Experiment_Num = @experimentIdText
                            --
                            SELECT @myError = @@error, @myRowCount = @@rowcount

                            If @experimentId Is Null
                            Begin
                                Set @message = 'Experiment not found for channel ' + Cast(@channelNum As varchar(12)) + ': ' + @experimentIdText
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
                        Where Channel_Type_Name = @channelTypeName
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
                        Values (@channelNum, @experimentId, @channelTypeId, '', 0)
                    End

                End -- </ExperimentIdDefined>

            End -- </ProcessChannelParam>

            Set @channelNum = @channelNum + 1
        End
    End

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
	-- Action for add mode or update mode
	---------------------------------------------------
	
	If @mode IN ('add', 'update')
	Begin -- <AddOrUpdate>

        MERGE [dbo].[T_Experiment_Plex_Members] AS t
        USING (SELECT Channel, Exp_ID, Channel_Type_ID, [Comment] 
               FROM #TmpExperiment_Plex_Members) as s
        ON ( t.[Channel] = s.[Channel] AND t.[Plex_Exp_ID] = @plexExperimentId)
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
            VALUES(@plexExperimentId, s.[Channel], s.[Exp_ID], s.[Channel_Type_ID], s.[Comment])
        WHEN NOT MATCHED BY SOURCE And T.Plex_exp_id = @plexExperimentId THEN DELETE;
		--
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
		If @myError <> 0
		Begin
			Set @msg = 'Update operation failed: "' + @plexExperimentId + '"'
			RAISERROR (@msg, 11, 18)
		End

        /*
		Set @compoundID = SCOPE_IDENTITY()
		
		Declare @StateID int = 1
		
		-- If @callingUser is defined, call AlterEventLogEntryUser to alter the Entered_By field in T_Event_Log
		If Len(@callingUser) > 0
			Exec AlterEventLogEntryUser 13, @compoundID, @StateID, @callingUser

        */

	End -- </AddOrUpdate>

	End TRY
	Begin CATCH 
		EXEC FormatErrorMessage @message output, @myError output
		
		-- rollback any open transactions
		If (XACT_STATE()) <> 0
			ROLLBACK TRANSACTION;

		If @logErrors > 0
		Begin
			Declare @logMessage varchar(1024) = @message + '; Plex Exp ID ' + @plexExperimentIdText
			exec PostLogEntry 'Error', @logMessage, 'AddUpdateExperimentPlexMembers'
		End

	End CATCH

	return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateExperimentPlexMembers] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateExperimentPlexMembers] TO [DMS_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateExperimentPlexMembers] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateExperimentPlexMembers] TO [Limited_Table_Write] AS [dbo]
GO
