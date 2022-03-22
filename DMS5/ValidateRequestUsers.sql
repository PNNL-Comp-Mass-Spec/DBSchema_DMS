/****** Object:  StoredProcedure [dbo].[ValidateRequestUsers] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[ValidateRequestUsers]
/****************************************************
**
**  Desc:
**      Validates the requested personnel and assigned personnel 
**      for a Data Analysis Request or Sample Prep Request
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**  Date:   03/21/2022 mem - Initial version (refactored code from AddUpdateSamplePrepRequest)
**
*****************************************************/
(
    @requestName varchar(128),
    @callingProcedure varchar(64),              -- AddUpdateDataAnalysisRequest or AddUpdateSamplePrepRequest
    @requestedPersonnel varchar(256) output,    -- Input/output parameter
    @assignedPersonnel varchar(256)  output,    -- Input/output parameter
    @requireValidRequestedPersonnel tinyint = 1,
    @message varchar(1024) Output
)
As
    Set XACT_ABORT, nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Set @requestName = IsNull(@requestName, '(unnamed request)')
    Set @callingProcedure = IsNull(@callingProcedure, '(unknown caller)')
    Set @requestedPersonnel = IsNull(@requestedPersonnel, '')
    Set @assignedPersonnel = IsNull(@assignedPersonnel, '')
    Set @requireValidRequestedPersonnel = IsNull(@requireValidRequestedPersonnel, 1)

    Set @message = ''

    ---------------------------------------------------
    -- Validate requested and assigned personnel
    -- Names should be in the form "Last Name, First Name (PRN)"
    ---------------------------------------------------

    CREATE TABLE #Tmp_UserInfo (
        EntryID int identity(1,1),
        [Name_and_PRN] varchar(255) NOT NULL,
        [User_ID] int NULL
    )

    Declare @nameValidationIteration int = 1
    Declare @userFieldName varchar(32) = ''
    Declare @cleanNameList varchar(255)

    While @nameValidationIteration <= 2
    Begin -- <a>

        DELETE FROM #Tmp_UserInfo

        If @nameValidationIteration = 1
        Begin
            INSERT INTO #Tmp_UserInfo ( Name_and_PRN )
            SELECT Value
            FROM dbo.udfParseDelimitedList(@requestedPersonnel, ';', @callingProcedure)
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            Set @userFieldName = 'requested personnel'
        End
        Else
        Begin
            INSERT INTO #Tmp_UserInfo ( Name_and_PRN )
            SELECT Value
            FROM dbo.udfParseDelimitedList(@assignedPersonnel, ';', @callingProcedure)
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            Set @userFieldName = 'assigned personnel'
        End

        UPDATE #Tmp_UserInfo
        SET [User_ID] = U.ID
        FROM #Tmp_UserInfo
            INNER JOIN T_Users U
            ON #Tmp_UserInfo.Name_and_PRN = U.Name_with_PRN
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        -- Use User_ID of 0 if the name is 'na'
        -- Set User_ID to 0
        UPDATE #Tmp_UserInfo
        SET [User_ID] = 0
        WHERE Name_and_PRN IN ('na')

        ---------------------------------------------------
        -- Look for entries in #Tmp_UserInfo where Name_and_PRN did not resolve to a User_ID
        -- Try-to auto-resolve using the U_Name and U_PRN columns in T_Users
        ---------------------------------------------------

        Declare @entryID int = 0
        Declare @continue tinyint = 1
        Declare @unknownUser varchar(255)
        Declare @matchCount tinyint
        Declare @newPRN varchar(64)
        Declare @newUserID int

        While @continue = 1
        Begin -- <b>
            SELECT TOP 1 @entryID = EntryID,
                        @unknownUser = Name_and_PRN
            FROM #Tmp_UserInfo
            WHERE EntryID > @entryID AND [USER_ID] IS NULL
            ORDER BY EntryID
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            If @myRowCount = 0
                Set @continue = 0
            Else
            Begin -- <c>
                Set @matchCount = 0

                exec AutoResolveNameToPRN @unknownUser, @matchCount output, @newPRN output, @newUserID output

                If @matchCount = 1
                Begin
                    -- Single match was found; update [User_ID] in #Tmp_UserInfo
                    UPDATE #Tmp_UserInfo
                    SET [User_ID] = @newUserID
                    WHERE EntryID = @entryID

                End
            End -- </c>

        End -- </b>

        If Exists (SELECT * FROM #Tmp_UserInfo WHERE [User_ID] Is Null)
        Begin
            Declare @firstInvalidUser varchar(255) = ''

            SELECT TOP 1 @firstInvalidUser = Name_and_PRN
            FROM #Tmp_UserInfo
            WHERE [USER_ID] IS NULL

            Set @message = 'Invalid username for ' + @userFieldName + ': "' + @firstInvalidUser + '"'
            Return 10
        End

        If @nameValidationIteration = 1 And @requireValidRequestedPersonnel > 0 And Not Exists (SELECT * FROM #Tmp_UserInfo WHERE User_ID > 0)
        Begin
            -- Requested personnel person must be a specific person (or list of people)
            Set @message = 'The Requested Personnel person must be a specific DMS user; "' + @requestedPersonnel + '" is invalid'
            Return 11
        End

        If @nameValidationIteration = 2
           And Exists (SELECT * FROM #Tmp_UserInfo WHERE User_ID > 0)
           And Exists (SELECT * FROM #Tmp_UserInfo WHERE Name_and_PRN = 'na')
        Begin
            -- Auto-remove the 'na' user since an actual person is defined
            DELETE FROM #Tmp_UserInfo WHERE Name_and_PRN = 'na'
        End

        -- Make sure names are capitalized properly
        --
        UPDATE #Tmp_UserInfo
        SET Name_and_PRN = U.Name_with_PRN
        FROM #Tmp_UserInfo
            INNER JOIN T_Users U
            ON #Tmp_UserInfo.User_ID = U.ID
        WHERE #Tmp_UserInfo.User_ID <> 0

        -- Regenerate the list of names
        --
        Set @cleanNameList = ''

        SELECT @cleanNameList = @cleanNameList + CASE
                                                     WHEN @cleanNameList = '' THEN ''
                                                     ELSE '; '
                                                 END + Name_and_PRN
        FROM #Tmp_UserInfo
        ORDER BY EntryID

        If @nameValidationIteration = 1
        Begin
            Set @requestedPersonnel = @cleanNameList
        End
        Else
        Begin
            Set @assignedPersonnel = @cleanNameList
        End

        Set @nameValidationIteration = @nameValidationIteration + 1

    End -- </a>

    return 0


GO
GRANT VIEW DEFINITION ON [dbo].[ValidateRequestUsers] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[ValidateRequestUsers] TO [Limited_Table_Write] AS [dbo]
GO
