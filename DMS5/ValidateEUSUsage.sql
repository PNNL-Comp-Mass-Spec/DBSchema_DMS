/****** Object:  StoredProcedure [dbo].[ValidateEUSUsage] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[ValidateEUSUsage]
/****************************************************
**
**  Desc:
**      Verifies that given usage type, proposal ID,
**      and user list are valid for DMS
**
**      Clears contents of @eusProposalID and @eusUsersList
**      for certain values of @eusUsageType
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**  Date:   07/11/2007 grk - Initial Version
**          09/09/2010 mem - Added parameter @autoPopulateUserListIfBlank
**                         - Now auto-clearing @eusProposalID and @eusUsersList if @eusUsageType is not 'USER'
**          12/12/2011 mem - Now auto-fixing @eusUsageType if it is an abbreviated form of Cap_Dev, Maintenance, or Broken
**          11/20/2013 mem - Now automatically extracting the integers from @eusUsersList if it instead has user names and integers
**          08/11/2015 mem - Now trimming spaces from the parameters
**          10/01/2015 mem - When @eusUsageType is '(ignore)' we now auto-change it to 'CAP_DEV'
**          04/06/2016 mem - Now using Try_Convert to convert from text to int
**          01/09/2016 mem - Added option for disabling EUS validation using table T_MiscOptions
**          01/20/2017 mem - Auto-fix USER_UNKOWN to USER_UNKNOWN for @eusUsageType
**          03/17/2017 mem - Only call MakeTableFromList if @eusUsersList contains a semicolon
**          04/10/2017 mem - Auto-change USER_UNKNOWN to CAP_DEV
**          07/19/2019 mem - Custom error message if @eusUsageType is blank
**          11/06/2019 mem - Auto-change @eusProposalID if a value is defined for Proposal_ID_AutoSupersede
**          08/12/2020 mem - Add support for a series of superseded proposals
**          08/14/2020 mem - Add safety check in case of a circular references (proposal 1 superseded by proposal 2, which is superseded by proposal 1)
**          08/18/2020 mem - Add missing Else keyword
**          08/20/2020 mem - When a circular reference exists, choose the proposal with the highest numeric ID
**          05/25/2021 mem - Add parameter @samplePrepRequest
**
*****************************************************/
(
    @eusUsageType varchar(50) output,
    @eusProposalID varchar(10) output,
    @eusUsersList varchar(1024) output,         -- Comma separated list of EUS user IDs (integers); also supports the form "Baker, Erin (41136)"
    @eusUsageTypeID int output,
    @message varchar(1024) output,
    @autoPopulateUserListIfBlank tinyint = 0,   -- When 1, will auto-populate @eusUsersList if it is empty and @eusUsageType is 'USER', 'USER_ONSITE', or 'USER_REMOTE'
    @samplePrepRequest tinyint = 0,             -- When 1, validating EUS fields for a sample prep request
    @infoOnly tinyint = 0                       -- When 1, show debug info
)
As
    set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Declare @n int
    Declare @UserCount int
    Declare @PersonID int
    Declare @NewUserList varchar(1024)
    Declare @enabledForPrepRequests tinyint = 0

    Declare @originalProposalID varchar(10)
    Declare @numericID int
    Declare @autoSupersedeProposalID varchar(10)
    Declare @checkSuperseded tinyint
    Declare @iterations tinyint

    Declare @logMessage varchar(255)

    Set @message = ''
    Set @eusUsersList = IsNull(@eusUsersList, '')
    Set @autoPopulateUserListIfBlank = IsNull(@autoPopulateUserListIfBlank, 0)
    Set @infoOnly = IsNull(@infoOnly, 0)

    ---------------------------------------------------
    -- Remove leading and trailing spaces, and check for nulls
    ---------------------------------------------------
    --
    Set @eusUsageType  = LTrim(RTrim(IsNull(@eusUsageType, '')))
    Set @eusProposalID = LTrim(RTrim(IsNull(@eusProposalID, '')))
    Set @eusUsersList  = LTrim(RTrim(IsNull(@eusUsersList, '')))

    If @eusUsageType = '(ignore)' AND Not Exists (SELECT * FROM T_EUS_UsageType WHERE [Name] = @eusUsageType)
    Begin
        Set @eusUsageType = 'CAP_DEV'
        Set @eusProposalID = ''
        Set @eusUsersList = ''
    End

    ---------------------------------------------------
    -- Auto-fix @eusUsageType if it is an abbreviated form of Cap_Dev, Maintenance, or Broken
    ---------------------------------------------------
    --
    If @eusUsageType Like 'Cap%' AND Not Exists (SELECT * FROM T_EUS_UsageType WHERE [Name] = @eusUsageType)
        Set @eusUsageType = 'CAP_DEV'

    If @eusUsageType Like 'Maint%' AND Not Exists (SELECT * FROM T_EUS_UsageType WHERE [Name] = @eusUsageType)
        Set @eusUsageType = 'MAINTENANCE'

    If @eusUsageType Like 'Brok%' AND Not Exists (SELECT * FROM T_EUS_UsageType WHERE [Name] = @eusUsageType)
        Set @eusUsageType = 'BROKEN'

    If @eusUsageType Like 'USER_UNKOWN%'
        Set @eusUsageType = 'USER_UNKNOWN'

    ---------------------------------------------------
    -- Auto-change USER_UNKNOWN to CAP_DEV
    -- Monthly EUS instrument usage validation will not allow USER_UNKNOWN but will allow CAP_DEV
    ---------------------------------------------------
    --
    If @eusUsageType = 'USER_UNKNOWN'
        Set @eusUsageType = 'CAP_DEV'

    ---------------------------------------------------
    -- Confirm that EUS validation is enabled
    ---------------------------------------------------
    --
    Declare @validateEUSData tinyint = 1

    SELECT @validateEUSData = Value
    FROM T_MiscOptions
    WHERE (Name = 'ValidateEUSData')
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myRowCount = 0
        Set @validateEUSData = 1

    If IsNull(@validateEUSData, 0) = 0
    Begin
        -- Validation is disabled
        Set @eusUsageTypeID = 10
        Set @eusProposalID = null
        Return 0
    End

    ---------------------------------------------------
    -- Resolve EUS usage type name to ID
    ---------------------------------------------------

    If @eusUsageType = ''
    Begin
        Set @message = 'EUS usage type cannot be blank'
        return 51071
    End

    Set @eusUsageTypeID = 0
    --
    SELECT @eusUsageTypeID = ID, @enabledForPrepRequests = Enabled_Prep_Request
    FROM T_EUS_UsageType
    WHERE (Name = @eusUsageType)
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        Set @message = 'Error trying to resolve EUS usage type: "' + @eusUsageType + '"'
        return 51070
    End
    --
    If @eusUsageTypeID = 0
    Begin
        Set @message = 'Could not resolve EUS usage type: "' + @eusUsageType + '"'
        return 51071
    End

    If @samplePrepRequest > 0 And @enabledForPrepRequests = 0
    Begin
        If @eusUsageType = 'USER'
            Set @message = 'Please choose usage type USER_ONSITE if processing a sample from an onsite user or USER_REMOTE if from a remote user'
        Else
            Set @message = 'EUS usage type: "' + @eusUsageType + '" is not allowed for Sample Prep Requests'

        return 51072
    End

    ---------------------------------------------------
    -- Validate EUS proposal and user
    -- if EUS usage type requires them
    ---------------------------------------------------
    --
    If @eusUsageType <> 'USER'
    Begin
        -- Make sure no proposal ID or users are specified
        If IsNull(@eusProposalID, '') <> '' OR @eusUsersList <> ''
            Set @message = 'Warning: Cleared proposal ID and/or users since usage type is "' + @eusUsageType + '"'

        Set @eusProposalID = NULL
        Set @eusUsersList = ''
    End
    
    If @eusUsageType = 'USER'
    Begin -- <a>

        ---------------------------------------------------
        -- Proposal and user list cannot be blank when the usage type is 'USER'
        ---------------------------------------------------
        If IsNull(@eusProposalID, '') = ''
        Begin
            Set @message = 'A Proposal ID must be selected for usage type "' + @eusUsageType + '"'
            return 51073
        End

        ---------------------------------------------------
        -- Verify EUS proposal ID and get the Numeric_ID value
        ---------------------------------------------------

        SELECT @numericID = Numeric_ID
        FROM T_EUS_Proposals
        WHERE Proposal_ID = @eusProposalID
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @myRowCount = 0
        Begin
            Set @message = 'Unknown EUS proposal ID: "' + @eusProposalID + '"'
            return 51075
        End

        ---------------------------------------------------
        -- Check for a superseded proposal
        ---------------------------------------------------
        --
        -- Create a table to track superseded proposals in the case of a circular reference
        -- E.g. two proposals with the same name, but different IDs (and likely different start or end dates)
        CREATE TABLE #Tmp_Proposal_Stack (
            Entry_ID int identity(1,1),
            Proposal_ID varchar(24),
            Numeric_ID int Not Null
        )

        Set @originalProposalID = @eusProposalID
        Set @checkSuperseded = 1
        Set @iterations = 0

        While @checkSuperseded = 1 AND @iterations < 30
        Begin -- <b>
            Set @autoSupersedeProposalID = ''
            Set @iterations = @iterations + 1

            SELECT @autoSupersedeProposalID = Proposal_ID_AutoSupersede
            FROM T_EUS_Proposals
            WHERE Proposal_ID = @eusProposalID
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            If IsNull(@autoSupersedeProposalID, '') = ''
            Begin
                Set @checkSuperseded = 0
            End
            Else
            Begin -- <c>
                If @eusProposalID = @autoSupersedeProposalID
                Begin
                    Set @logMessage = 'Proposal ' + Coalesce(@eusProposalID, '??') + ' in T_EUS_Proposals ' +
                                      'has Proposal_ID_AutoSupersede set to itself; this is invalid'

                    If @infoOnly = 0
                        exec PostLogEntry 'Error', @logMessage, 'ValidateEUSUsage', 1
                    Else
                        Print @logMessage

                    Set @checkSuperseded = 0
                End
                Else
                Begin -- <d>
                    IF Not Exists (SELECT * FROM T_EUS_Proposals WHERE Proposal_ID = @autoSupersedeProposalID)
                    Begin
                        Set @logMessage = 'Proposal ' + Coalesce(@eusProposalID, '??') + ' in T_EUS_Proposals ' +
                                          'has Proposal_ID_AutoSupersede set to ' + Coalesce(@autoSupersedeProposalID, '??') + ', ' +
                                          'but that proposal does not exist in T_EUS_Proposals'

                        If @infoOnly = 0
                            exec PostLogEntry 'Error', @logMessage, 'ValidateEUSUsage', 1
                        Else
                            Print @logMessage

                        Set @checkSuperseded = 0
                    End
                    Else
                    Begin
                        If NOT EXISTS (SELECT * FROM #Tmp_Proposal_Stack)
                        Begin
                            INSERT INTO #Tmp_Proposal_Stack (Proposal_ID, Numeric_ID)
                            Values (@eusProposalID, Coalesce(@numericID, 0))
                        End

                        SELECT @numericID = Numeric_ID
                        FROM T_EUS_Proposals
                        WHERE Proposal_ID = @autoSupersedeProposalID

                        If EXISTS (SELECT * FROM #Tmp_Proposal_Stack WHERE Proposal_ID = @autoSupersedeProposalID)
                        Begin
                            -- Circular reference
                            If @infoOnly > 0
                            Begin
                                Print 'Circular reference found; choosing the one with the highest ID'
                            END

                            SELECT TOP 1 @eusProposalID = Proposal_ID
                            FROM #Tmp_Proposal_Stack
                            ORDER BY Numeric_ID Desc, Proposal_ID Desc

                            If @originalProposalID = @eusProposalID
                            Begin
                                Set @message = ''
                            End
                            Else
                            Begin
                                Set @message = 'Proposal ' + @originalProposalID + ' is superseded by ' + @eusProposalID
                            End

                            Set @checkSuperseded = 0
                        End
                        Else
                        Begin
                            INSERT INTO #Tmp_Proposal_Stack (Proposal_ID, Numeric_ID)
                            Values (@autoSupersedeProposalID, Coalesce(@numericID, 0))

                            Set @message = dbo.AppendToText(
                                    @message,
                                    'Proposal ' + @eusProposalID + ' is superseded by ' + @autoSupersedeProposalID,
                                    0, '; ', 1024)

                            Set @eusProposalID = @autoSupersedeProposalID
                        End
                    End
                End -- </d>
            End -- </c>
        End -- </b>

        If @infoOnly > 0 AND EXISTS (SELECT * from #Tmp_Proposal_Stack)
        Begin
            SELECT *
            FROM #Tmp_Proposal_Stack
            ORDER BY Entry_ID
        End

        ---------------------------------------------------
        -- Check for a blank user list
        ---------------------------------------------------

        If @eusUsersList = ''
        Begin
            -- Blank user list
            --
            If @autoPopulateUserListIfBlank = 0
            Begin
                Set @message = 'Associated users must be selected for usage type "' + @eusUsageType + '"'
                return 51074
            End

            -- Auto-populate @eusUsersList with the first user associated with the given user proposal
            --
            Set @PersonID = 0

            SELECT @PersonID = MIN(EUSU.Person_ID)
            FROM T_EUS_Proposals EUSP
                INNER JOIN T_EUS_Proposal_Users EUSU
                ON EUSP.Proposal_ID = EUSU.Proposal_ID
            WHERE (EUSP.Proposal_ID = @eusProposalID)

            If IsNull(@PersonID, 0) > 0
            Begin
                Set @eusUsersList = Convert(varchar(12), @PersonID)
                Set @message = dbo.AppendToText(
                                @message,
                                'Warning: EUS User list was empty; auto-selected user "' + @eusUsersList + '"',
                                0, '; ', 1024)
            End
        End

        ---------------------------------------------------
        -- Verify that all users in list have access to
        -- given proposal
        ---------------------------------------------------

        If @eusUsersList <> ''
        Begin -- <e>

            If @eusUsersList Like '%[A-Z]%' And @eusUsersList Like '%([0-9]%' And @eusUsersList Like '%[0-9])%'
            Begin
                -- @eusUsersList has entries of the form "Baker, Erin (41136)"
                -- Parse @eusUsersList to only keep the integers and commas
                --
                Declare @StringLength int = Len(@eusUsersList)
                Declare @CharNum int = 1
                Declare @IntegerList varchar(1024) = ''

                While @CharNum <= @StringLength
                Begin
                    Declare @CurrentChar char = Substring(@eusUsersList, @CharNum, 1)

                    If @CurrentChar = ',' Or Not Try_Convert(int, @CurrentChar) Is Null
                    Begin
                        Set @IntegerList = @IntegerList + @CurrentChar
                    End

                    Set @CharNum = @CharNum + 1
                End

                Set @eusUsersList = @IntegerList
            End


            Declare @tmpUsers TABLE
            (
                Item varchar(256)
            )

            -- Split items in @eusUsersList on commas
            --
            If @eusUsersList Like '%,%'
            Begin
                INSERT INTO @tmpUsers (Item)
                SELECT Item
                FROM MakeTableFromList(@eusUsersList)
            End
            Else
            Begin
                INSERT INTO @tmpUsers (Item)
                VALUES (@eusUsersList)
            End

            -- Look for entries that are not integers
            --
            Set @n = 0
            SELECT @n = Count(*)
            FROM @tmpUsers
            WHERE Try_Convert(INT, item) IS NULL

            If @n > 0
            Begin
                If @n = 1
                    Set @message = 'EMSL User ID is not numeric'
                else
                    Set @message = Cast(@n as varchar(12)) + ' EMSL User IDs are not numeric'
                return 51077
            End

            -- Look for entries that are not in T_EUS_Proposal_Users
            --
            Set @n = 0
            SELECT @n = count(*)
            FROM @tmpUsers
            WHERE
                CAST(Item as int) NOT IN
                (
                    SELECT Person_ID
                    FROM  T_EUS_Proposal_Users
                    WHERE Proposal_ID = @eusProposalID
                )
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount
            --
            If @myError <> 0
            Begin
                Set @message = 'Error trying to verify that all users are associated with proposal'
                return 51078
            End

            If @n <> 0
            Begin -- <f>

                -- Invalid users were found
                --
                If @autoPopulateUserListIfBlank = 0
                Begin
                    Set @message = Convert(varchar(12), @n)
                    If @n = 1
                        Set @message = @message + ' user is'
                    Else
                        Set @message = @message + ' users are'

                    Set @message = @message + ' not associated with the specified proposal'
                    return 51079
                End

                -- Auto-remove invalid entries from @tmpUsers
                --
                DELETE
                FROM  @tmpUsers
                WHERE
                    CAST(Item as int) NOT IN
                    (
                        SELECT Person_ID
                        FROM  T_EUS_Proposal_Users
                        WHERE Proposal_ID = @eusProposalID
                    )

                Set @UserCount = 0
                SELECT @UserCount = COUNT(*)
                FROM @tmpUsers

                Set @NewUserList = ''

                If @UserCount >= 1
                Begin
                    -- Reconstruct the users list
                    Set @NewUserList = ''
                    SELECT @NewUserList = @NewUserList + ', ' + Item
                    FROM @tmpUsers

                    -- Remove the first two characters
                    If IsNull(@NewUserList, '') <> ''
                        Set @NewUserList = SubString(@NewUserList, 3, Len(@NewUserList))
                End

                If IsNull(@NewUserList, '') = ''
                Begin
                    -- Auto-populate @eusUsersList with the first user associated with the given user proposal
                    Set @PersonID = 0

                    SELECT @PersonID = MIN(EUSU.Person_ID)
                    FROM T_EUS_Proposals EUSP
                        INNER JOIN T_EUS_Proposal_Users EUSU
                        ON EUSP.Proposal_ID = EUSU.Proposal_ID
                    WHERE (EUSP.Proposal_ID = @eusProposalID)

                    If IsNull(@PersonID, 0) > 0
                        Set @NewUserList = Convert(varchar(12), @PersonID)
                End

                Set @eusUsersList = IsNull(@NewUserList, '')
                Set @message = dbo.AppendToText(
                        @message,
                        'Warning: Removed users from EUS User list that are not associated with proposal "' + @eusProposalID + '"',
                        0, '; ', 1024)

            End -- </f>
        End -- </e>
    End -- </a>

    return 0

GO
GRANT VIEW DEFINITION ON [dbo].[ValidateEUSUsage] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[ValidateEUSUsage] TO [Limited_Table_Write] AS [dbo]
GO
