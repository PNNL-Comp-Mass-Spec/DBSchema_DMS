/****** Object:  StoredProcedure [dbo].[validate_eus_usage] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[validate_eus_usage]
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
**          03/17/2017 mem - Only call make_table_from_list if @eusUsersList contains a semicolon
**          04/10/2017 mem - Auto-change USER_UNKNOWN to CAP_DEV
**          07/19/2019 mem - Custom error message if @eusUsageType is blank
**          11/06/2019 mem - Auto-change @eusProposalID if a value is defined for Proposal_ID_AutoSupersede
**          08/12/2020 mem - Add support for a series of superseded proposals
**          08/14/2020 mem - Add safety check in case of a circular references (proposal 1 superseded by proposal 2, which is superseded by proposal 1)
**          08/18/2020 mem - Add missing Else keyword
**          08/20/2020 mem - When a circular reference exists, choose the proposal with the highest numeric ID
**          05/25/2021 mem - Add parameter @samplePrepRequest
**          05/26/2021 mem - Capitalize @eusUsageType
**          05/27/2021 mem - Add parameters @experimentID, @campaignID, and @addingItem
**          09/29/2021 mem - Assure that EUS Usage Type is 'USER_ONSITE' if associated with a Resource Owner proposal
**          10/13/2021 mem - Use Like when extracting integers
**                         - Add additional debug messages
**                         - Use Try_Parse to convert from text to int, since Try_Convert('') gives 0
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @eusUsageType varchar(50) output,
    @eusProposalID varchar(10) output,
    @eusUsersList varchar(1024) output,         -- Comma separated list of EUS user IDs (integers); also supports the form "Baker, Erin (41136)"; does not support "Baker, Erin"
    @eusUsageTypeID int output,
    @message varchar(1024) output,
    @autoPopulateUserListIfBlank tinyint = 0,   -- When 1, will auto-populate @eusUsersList if it is empty and @eusUsageType is 'USER', 'USER_ONSITE', or 'USER_REMOTE'
    @samplePrepRequest tinyint = 0,             -- When 1, validating EUS fields for a sample prep request
    @experimentID int = 0,                      -- When non-zero, validate EUS Usage Type against the experiment's campaign
    @campaignID int = 0,                        -- When non-zero, validate EUS Usage Type against the campaign
    @addingItem tinyint = 0,                    -- When @experimentID or @campaignID is non-zero, set this to 1 if creating a new prep request or new requested run
    @infoOnly tinyint = 0                       -- When 1, show debug info
)
AS
    set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Declare @n int
    Declare @userCount int
    Declare @personID int
    Declare @newUserList varchar(1024)
    Declare @enabledForPrepRequests tinyint = 0
    Declare @eusUsageTypeName varchar(50)

    Declare @originalProposalID varchar(10)
    Declare @numericID int
    Declare @proposalType varchar(100)
    Declare @usageTypeUpdated tinyint = 0

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
    WHERE Name = 'ValidateEUSData'
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
    SELECT @eusUsageTypeID = ID,
           @eusUsageTypeName = Name,
           @enabledForPrepRequests = Enabled_Prep_Request
    FROM T_EUS_UsageType
    WHERE Name = @eusUsageType
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
        Begin
            Set @message = 'Please choose usage type USER_ONSITE if processing a sample from an onsite user or a sample for a Resource Owner project; ' +
                           'choose USER_REMOTE if processing a sample for an EMSL user'
        End
        Else
        Begin
            Set @message = 'EUS usage type: "' + @eusUsageType + '" is not allowed for Sample Prep Requests'
        End

        return 51072
    End

    Set @eusUsageType = @eusUsageTypeName

    ---------------------------------------------------
    -- Validate EUS proposal and user
    -- if EUS usage type requires them
    ---------------------------------------------------
    --
    If @eusUsageType Not In ('USER', 'USER_ONSITE', 'USER_REMOTE')
    Begin
        -- Make sure no proposal ID or users are specified
        If IsNull(@eusProposalID, '') <> '' OR @eusUsersList <> ''
            Set @message = 'Warning: Cleared proposal ID and/or users since usage type is "' + @eusUsageType + '"'

        Set @eusProposalID = NULL
        Set @eusUsersList = ''
    End

    If @eusUsageType In ('USER', 'USER_ONSITE', 'USER_REMOTE')
    Begin -- <a1>

        ---------------------------------------------------
        -- Proposal and user list cannot be blank when the usage type is 'USER', 'USER_ONSITE', or 'USER_REMOTE'
        ---------------------------------------------------
        If IsNull(@eusProposalID, '') = ''
        Begin
            Set @message = 'A Proposal ID must be selected for usage type "' + @eusUsageType + '"'
            return 51073
        End

        ---------------------------------------------------
        -- Verify EUS proposal ID, get the Numeric_ID value, get the proposal type
        ---------------------------------------------------

        SELECT @numericID = Numeric_ID, @proposalType = Proposal_Type
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
                        exec post_log_entry 'Error', @logMessage, 'validate_eus_usage', 1
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
                            exec post_log_entry 'Error', @logMessage, 'validate_eus_usage', 1
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

                            Set @message = dbo.append_to_text(
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

        If @eusProposalID <> @originalProposalID
        Begin
            SELECT @proposalType = Proposal_Type
            FROM T_EUS_Proposals
            WHERE Proposal_ID = @eusProposalID
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
            Set @personID = 0

            SELECT @personID = MIN(EUSU.Person_ID)
            FROM T_EUS_Proposals EUSP
                INNER JOIN T_EUS_Proposal_Users EUSU
                ON EUSP.Proposal_ID = EUSU.Proposal_ID
            WHERE EUSP.Proposal_ID = @eusProposalID

            If IsNull(@personID, 0) > 0
            Begin
                Set @eusUsersList = Convert(varchar(12), @personID)
                Set @message = dbo.append_to_text(
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
                If @infoOnly > 0
                    Print 'Parsing ' + @eusUsersList

                -- @eusUsersList has entries of the form "Baker, Erin (41136)"
                -- Parse @eusUsersList to only keep the integers and commas
                --
                Declare @stringLength int = Len(@eusUsersList)
                Declare @charNum int = 1
                Declare @integerList varchar(1024) = ''

                While @charNum <= @stringLength
                Begin
                    Declare @currentChar char = Substring(@eusUsersList, @charNum, 1)

                    If @currentChar = ',' Or @currentChar Like '[0-9]'
                    Begin
                        Set @integerList = @integerList + @currentChar
                    End

                    Set @charNum = @charNum + 1
                End

                Set @eusUsersList = @integerList
            End

            If @eusUsersList Like ',%'
            Begin
                -- Trim the leading comma
                Set @eusUsersList = Substring(@eusUsersList, 2, Len(@eusUsersList))
            End

            If @eusUsersList Like '%,'
            Begin
                -- Trim the trailing comma
                Set @eusUsersList = Substring(@eusUsersList, 1, Len(@eusUsersList) - 1)
            End

            Declare @tmpUsers TABLE
            (
                Item varchar(256)
            )

            If @infoOnly > 0
                Print 'Splitting: "' + @eusUsersList + '"'

            -- Split items in @eusUsersList on commas
            --
            If @eusUsersList Like '%,%'
            Begin
                INSERT INTO @tmpUsers (Item)
                SELECT Item
                FROM make_table_from_list(@eusUsersList)
            End
            Else
            Begin
                INSERT INTO @tmpUsers (Item)
                VALUES (@eusUsersList)
            End

            If @infoOnly > 0
            Begin
                Select Item As EUS_UserID From @tmpUsers
            End

            -- Look for entries that are not integers
            --
            Set @n = 0
            SELECT @n = Count(*)
            FROM @tmpUsers
            WHERE Try_Parse(item as INT) IS NULL

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

                Set @userCount = 0
                SELECT @userCount = COUNT(*)
                FROM @tmpUsers

                Set @newUserList = ''

                If @userCount >= 1
                Begin
                    -- Reconstruct the users list
                    Set @newUserList = ''
                    SELECT @newUserList = @newUserList + ', ' + Item
                    FROM @tmpUsers

                    -- Remove the first two characters
                    If IsNull(@newUserList, '') <> ''
                        Set @newUserList = SubString(@newUserList, 3, Len(@newUserList))
                End

                If IsNull(@newUserList, '') = ''
                Begin
                    -- Auto-populate @eusUsersList with the first user associated with the given user proposal
                    Set @personID = 0

                    SELECT @personID = MIN(EUSU.Person_ID)
                    FROM T_EUS_Proposals EUSP
                        INNER JOIN T_EUS_Proposal_Users EUSU
                        ON EUSP.Proposal_ID = EUSU.Proposal_ID
                    WHERE EUSP.Proposal_ID = @eusProposalID

                    If IsNull(@personID, 0) > 0
                        Set @newUserList = Convert(varchar(12), @personID)
                End

                Set @eusUsersList = IsNull(@newUserList, '')
                Set @message = dbo.append_to_text(
                        @message,
                        'Warning: Removed users from EUS User list that are not associated with proposal "' + @eusProposalID + '"',
                        0, '; ', 1024)

            End -- </f>
        End -- </e>
    End -- </a1>

    If @campaignID > 0 OR @experimentID > 0
    Begin -- <a2>
        Declare @eusUsageTypeCampaign varchar(50)
        Declare @msg varchar(1024)

        If @campaignID > 0
        Begin
            SELECT @eusUsageTypeCampaign = EUT.Name
            FROM T_Campaign C
                 INNER JOIN T_EUS_UsageType EUT
                   ON C.CM_EUS_Usage_Type = EUT.ID
            WHERE C.Campaign_ID = @campaignID
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount
        End
        Else
        Begin
            SELECT @eusUsageTypeCampaign = EUT.Name
            FROM T_Experiments E
                 INNER JOIN T_Campaign C
                   ON E.EX_campaign_ID = C.Campaign_ID
                 INNER JOIN T_EUS_UsageType EUT
                   ON C.CM_EUS_Usage_Type = EUT.ID
            WHERE E.Exp_ID = @experimentID
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount
        End

        If @eusUsageTypeCampaign = 'USER_REMOTE' And @eusUsageType In ('USER_ONSITE', 'USER') And @proposalType <> 'Resource Owner'
        Begin
            If @addingItem > 0
            Begin
                Set @eusUsageType = 'USER_REMOTE'
                Set @msg = 'Auto-updated EUS Usage Type to USER_REMOTE since the campaign has USER_REMOTE'
                Set @usageTypeUpdated = 1
            End
            Else
            Begin
                Set @msg = 'Warning: campaign has EUS Usage Type USER_REMOTE; the new item should likely also be of type USER_REMOTE'
            End

            Set @message = dbo.append_to_text(@message, @msg, 0, '; ', 1024)
        End

        If @eusUsageTypeCampaign = 'USER_ONSITE' And @eusUsageType = 'USER' And @proposalType <> 'Resource Owner'
        Begin
            Set @eusUsageType = 'USER_ONSITE'
            Set @msg = 'Auto-updated EUS Usage Type to USER_ONSITE since the campaign has USER_ONSITE'
            Set @usageTypeUpdated = 1
        End
    End

    If @proposalType = 'Resource Owner' And @eusUsageType In ('USER_REMOTE', 'USER')
    Begin
        -- Requested runs for Resource Owner projects should always have EUS Usage Type 'USER_ONSITE'
        Set @eusUsageType = 'USER_ONSITE'
        Set @msg = 'Auto-updated EUS Usage Type to USER_ONSITE since associated with a Resource Owner project'
        Set @usageTypeUpdated = 1
    End

    If @usageTypeUpdated > 0
    Begin
        Set @message = dbo.append_to_text(@message, @msg, 0, '; ', 1024)

        SELECT @eusUsageTypeID = ID
        FROM T_EUS_UsageType
        WHERE Name = @eusUsageType
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @myRowCount= 0
        Begin
            Set @msg = @msg + '; Could not find usage type "' + @eusUsageType + '" in T_EUS_UsageType; this is unexpected'
            exec post_log_entry 'Error', @msg, 'validate_eus_usage'

            -- Only append @msg to @message if an error occurs
            Set @message = dbo.append_to_text(@message, @msg, 0, '; ', 1024)
        End
    End

    return 0

GO
GRANT VIEW DEFINITION ON [dbo].[validate_eus_usage] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[validate_eus_usage] TO [Limited_Table_Write] AS [dbo]
GO
