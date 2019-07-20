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
**          09/09/2010 mem - Added parameter @AutoPopulateUserListIfBlank
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
**
*****************************************************/
(
    @eusUsageType varchar(50) output,
    @eusProposalID varchar(10) output,
    @eusUsersList varchar(1024) output,         -- Comma separated list of EUS user IDs (integers); also supports the form "Baker, Erin (41136)"
    @eusUsageTypeID int output,
    @message varchar(512) output,
    @AutoPopulateUserListIfBlank tinyint = 0    -- When 1, then will auto-populate @eusUsersList if it is empty and @eusUsageType = 'USER'
)
As
    set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0
    
    Declare @n int
    Declare @UserCount int
    Declare @PersonID int
    Declare @NewUserList varchar(1024)
    
    set @message = ''
    Set @eusUsersList = IsNull(@eusUsersList, '')
    Set @AutoPopulateUserListIfBlank = IsNull(@AutoPopulateUserListIfBlank, 0)

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
        set @eusUsageTypeID = 10
        set @eusProposalID = null
        Return 0
    End
    
    ---------------------------------------------------
    -- Resolve EUS usage type name to ID
    ---------------------------------------------------

    If @eusUsageType = ''
    Begin
        set @message = 'EUS usage type cannot be blank'
        return 51071
    End

    set @eusUsageTypeID = 0
    --
    SELECT @eusUsageTypeID = ID
    FROM T_EUS_UsageType
    WHERE (Name = @eusUsageType)
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        set @message = 'Error trying to resolve EUS usage type: "' + @eusUsageType + '"'
        return 51070
    end
    --
    if @eusUsageTypeID = 0
    begin
        set @message = 'Could not resolve EUS usage type: "' + @eusUsageType + '"'
        return 51071
    end

    ---------------------------------------------------
    -- Validate EUS proposal and user
    -- if EUS usage type requires them
    ---------------------------------------------------
    --
    if @eusUsageType <> 'USER'
    begin
        -- Make sure no proposal ID or users are specified
        if IsNull(@eusProposalID, '') <> '' OR @eusUsersList <> ''
            Set @message = 'Warning: Cleared proposal ID and/or users since usage type is "' + @eusUsageType + '"'

        set @eusProposalID = NULL
        set @eusUsersList = ''
    end
    
    if @eusUsageType = 'USER'
    begin -- <a>

        ---------------------------------------------------
        -- Proposal and user list cannot be blank when the usage type is 'USER'
        ---------------------------------------------------
        if IsNull(@eusProposalID, '') = ''
        begin
            set @message = 'A Proposal ID must be selected for usage type "' + @eusUsageType + '"'
            return 51073
        end

        ---------------------------------------------------
        -- Verify EUS proposal ID
        ---------------------------------------------------
        
        IF NOT EXISTS (SELECT * FROM T_EUS_Proposals WHERE PROPOSAL_ID = @eusProposalID)    
        begin
            set @message = 'Unknown EUS proposal ID: "' + @eusProposalID + '"'
            return 51075
        end
        
        If @eusUsersList = ''
        Begin
            -- Blank user list
            --
            If @AutoPopulateUserListIfBlank = 0
            Begin
                set @message = 'Associated users must be selected for usage type "' + @eusUsageType + '"'
                return 51074
            End
        
            -- Auto-populate @eusUsersList with the first user associated with the given user proposal
            --
            Set @PersonID = 0
            
            SELECT @PersonID = MIN(EUSU.Person_ID)
            FROM T_EUS_Proposals EUSP
                INNER JOIN T_EUS_Proposal_Users EUSU
                ON EUSP.PROPOSAL_ID = EUSU.Proposal_ID
            WHERE (EUSP.PROPOSAL_ID = @eusProposalID)
            
            If IsNull(@PersonID, 0) > 0
            Begin
                Set @eusUsersList = Convert(varchar(12), @PersonID)
                Set @message = 'Warning: EUS User list was empty; auto-selected user "' + @eusUsersList + '"'
            End
        End
 
        
        If @eusUsersList <> ''
        Begin -- <b>
            ---------------------------------------------------
            -- Verify that all users in list have access to
            -- given proposal
            ---------------------------------------------------
            
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
            set @n = 0            
            SELECT @n = Count(*)
            FROM @tmpUsers
            WHERE Try_Convert(INT, item) IS NULL

            If @n > 0
            begin
                If @n = 1
                    set @message = 'EMSL User ID is not numeric'
                else
                    set @message = Cast(@n as varchar(12)) + ' EMSL User IDs are not numeric'
                return 51077
            end
            
            -- Look for entries that are not in T_EUS_Proposal_Users
            --
            set @n = 0
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
            if @myError <> 0
            begin
                set @message = 'Error trying to verify that all users are associated with proposal'
                return 51078
            end

            if @n <> 0
            begin -- <c>
            
                -- Invalid users were found
                --
                If @AutoPopulateUserListIfBlank = 0
                Begin
                    set @message = Convert(varchar(12), @n)
                    If @n = 1
                        set @message = @message + ' user is'
                    Else
                        set @message = @message + ' users are'
                        
                    set @message = @message + ' not associated with the specified proposal'
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

                set @UserCount = 0            
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
                    if IsNull(@NewUserList, '') <> ''
                        Set @NewUserList = SubString(@NewUserList, 3, Len(@NewUserList))
                End
                
                If IsNull(@NewUserList, '') = ''
                Begin
                    -- Auto-populate @eusUsersList with the first user associated with the given user proposal
                    Set @PersonID = 0
                    
                    SELECT @PersonID = MIN(EUSU.Person_ID)
                    FROM T_EUS_Proposals EUSP
                        INNER JOIN T_EUS_Proposal_Users EUSU
                        ON EUSP.PROPOSAL_ID = EUSU.Proposal_ID
                    WHERE (EUSP.PROPOSAL_ID = @eusProposalID)
                    
                    If IsNull(@PersonID, 0) > 0
                        Set @NewUserList = Convert(varchar(12), @PersonID)
                End
                
                Set @eusUsersList = IsNull(@NewUserList, '')
                Set @message = 'Warning: Removed users from EUS User list that are not associated with proposal "' + @eusProposalID + '"'
                                
            End -- </c>
            
        End -- </b>

    end -- </a>

    return 0

GO
GRANT VIEW DEFINITION ON [dbo].[ValidateEUSUsage] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[ValidateEUSUsage] TO [Limited_Table_Write] AS [dbo]
GO
