/****** Object:  StoredProcedure [dbo].[AddUpdateEUSProposals] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[AddUpdateEUSProposals]
/****************************************************
**
**  Desc: Adds new or updates existing EUS Proposals in database
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   jds
**  Date:   08/15/2006
**          11/16/2006 grk - fix problem with GetEUSPropID not able to return varchar (ticket #332)
**          04/01/2011 mem - Now updating State_ID in T_EUS_Proposal_Users
**          10/13/2015 mem - Added @EUSProposalType
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          11/06/2019 mem - Add @autoSupersedeProposalID
**                         - Rename @EUSPropState to @EUSPropStateID and make it an int instead of varchar
**                         - Add Try/Catch error handling
**                         - Fix merge query bug
**
*****************************************************/
(
    @EUSPropID varchar(10),
    @EUSPropStateID int,                      -- 1=New, 2=Active, 3=Inactive, 4=No Interest
    @EUSPropTitle varchar(2048),
    @EUSPropImpDate varchar(50),
    @EUSUsersList varchar(4096),
    @EUSProposalType varchar(100),
    @autoSupersedeProposalID varchar(10),
    @mode varchar(12) = 'add',                -- Add or Update
    @message varchar(512) output
)
AS
    Set XACT_ABORT, nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Set @message = ''

    Declare @msg varchar(256)
    Declare @logErrors tinyint = 1

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = VerifySPAuthorized 'AddUpdateEUSProposals', @raiseError = 1
    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;

    BEGIN TRY

    ---------------------------------------------------
    -- Validate input fields
    ---------------------------------------------------

    Set @myError = 0

    If LEN(@EUSPropID) < 1
    Begin
        Set @logErrors = 0
        Set @msg = 'EUS Proposal ID was blank'
        RAISERROR (@msg, 11, 1)
    End

    If @EUSPropStateID Is Null
    Begin
        Set @logErrors = 0
        Set @msg = 'EUS Proposal State cannot be null'
        RAISERROR (@msg, 11, 2)
    End

    If LEN(@EUSPropTitle) < 1
    Begin
        Set @logErrors = 0
        Set @msg = 'EUS Proposal Title was blank'
        RAISERROR (@msg, 11, 3)
    End

    Set @EUSPropImpDate = IsNull(@EUSPropImpDate, '')
    If LEN(@EUSPropImpDate) < 1
        Set @EUSPropImpDate = Convert(varchar(50), GetDate(), 120)

    If ISDATE(@EUSPropImpDate) <> 1
    Begin
        Set @logErrors = 0
        Set @msg = 'EUS Proposal Import Date was blank or an invalid date'
        RAISERROR (@msg, 11, 4)
    End

    If @EUSPropStateID = 2 and LEN(@EUSUsersList) < 1
    Begin
        Set @logErrors = 0
        Set @msg = 'An "Active" EUS Proposal must have at least 1 associated EMSL User'
        RAISERROR (@msg, 11, 4)
    End

    ---------------------------------------------------
    -- Is entry already in database?
    ---------------------------------------------------

    Declare @TempEUSPropID varchar(10) = '0'
    --
    SELECT @tempEUSPropID = Proposal_ID
    FROM T_EUS_Proposals
    WHERE Proposal_ID = @EUSPropID
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        Set @msg = 'Error trying to look for entry in table'
        RAISERROR (@msg, 11, 5)
    End

    -- Cannot create an entry that already exists
    --
    If @TempEUSPropID <> '0' and @mode = 'add'
    Begin
        Set @logErrors = 0
        Set @msg = 'Cannot add: EUS Proposal ID "' + @EUSPropID + '" is already in the database '
        RAISERROR (@msg, 11, 6)
    End

    -- Cannot update a non-existent entry
    --
    If @TempEUSPropID = '0' and @mode = 'update'
    Begin
        Set @logErrors = 0
        Set @msg = 'Cannot update: EUS Proposal ID "' + @EUSPropID + '" is not in the database '
        RAISERROR (@msg, 11, 7)
    End

    If Len(IsNull(@autoSupersedeProposalID, '')) > 0
    Begin
        -- Verify that @autoSupersedeProposalID exists
        --
        If Not Exists (SELECT * FROM T_EUS_Proposals WHERE Proposal_ID = @autoSupersedeProposalID)
        Begin
            Set @logErrors = 0
            Set @msg = 'Cannot supersede proposal "' + @EUSPropID + '" with "' + @autoSupersedeProposalID + '" since the new proposal is not in the database'
            RAISERROR (@msg, 11, 8)
        End

        If Ltrim(Rtrim(@autoSupersedeProposalID)) = Ltrim(Rtrim(@EUSPropID))
        Begin
            Set @logErrors = 0
            Set @msg = 'Cannot supersede proposal "' + @EUSPropID + '" with itself'
            RAISERROR (@msg, 11, 9)
        End
    End

    ---------------------------------------------------
    -- Action for add mode
    ---------------------------------------------------
    If @Mode = 'add'
    Begin

        INSERT INTO T_EUS_Proposals (
            Proposal_ID,
            [Title],
            State_ID,
            Import_Date,
            Proposal_Type,
            Proposal_ID_AutoSupersede
        ) VALUES (
            @EUSPropID,
            @EUSPropTitle,
            @EUSPropStateID,
            @EUSPropImpDate,
            @EUSProposalType,
            @autoSupersedeProposalID
        )

        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
        Begin
            Set @msg = 'Insert operation failed: "' + @EUSPropTitle + '"'
            RAISERROR (@msg, 11, 10)
        End

    End -- add mode

    ---------------------------------------------------
    -- Action for update mode
    ---------------------------------------------------
    --
    If @Mode = 'update'
    Begin
        Set @myError = 0
        --
        UPDATE T_EUS_Proposals
        SET
            [Title] = @EUSPropTitle,
            State_ID = @EUSPropStateID,
            Import_Date = @EUSPropImpDate,
            Proposal_Type = @EUSProposalType,
            Proposal_ID_AutoSupersede = @autoSupersedeProposalID
        WHERE Proposal_ID = @EUSPropID
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
        Begin
            Set @msg = 'Update operation failed: "' + @EUSPropTitle + '"'
            RAISERROR (@msg, 11, 11)
        End
    End -- update mode

    ---------------------------------------------------
    -- Associate users in @eusUsersList with the proposal
    -- by updating information in table T_EUS_Proposal_Users
    ---------------------------------------------------

    CREATE TABLE #tempEUSUsers (
            PERSON_ID int
           )

    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        Set @message = 'Error creating temporary user table'
        RAISERROR (@msg, 11, 12)
    End

    INSERT INTO #tempEUSUsers (Person_ID)
    SELECT EUS_Person_ID
    FROM ( SELECT CAST(Item AS int) AS EUS_Person_ID
           FROM MakeTableFromList ( @eusUsersList )
         ) SourceQ
         INNER JOIN T_EUS_Users
           ON SourceQ.EUS_Person_ID = T_EUS_Users.Person_ID
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        Set @message = 'Error trying to add user to temporary user table'
        RAISERROR (@msg, 11, 13)
    End

    ---------------------------------------------------
    -- Add associations between proposal and users
    -- who are in list, but not in association table
    ---------------------------------------------------
    --
    Declare @ProposalUserStateID int

    If @EUSPropStateID IN (1,2)
        Set @ProposalUserStateID = 1
    Else
        Set @ProposalUserStateID = 2

    MERGE T_EUS_Proposal_Users AS target
    USING
        (  SELECT @EUSPropID AS Proposal_ID,
                  Person_ID,
                  'Y' AS Of_DMS_Interest
            FROM #tempEUSUsers
        ) AS Source (Proposal_ID, Person_ID, Of_DMS_Interest)
    ON (target.Proposal_ID = source.Proposal_ID AND
        target.Person_ID = source.Person_ID)
    WHEN MATCHED AND IsNull(target.State_ID, 0) NOT IN (@ProposalUserStateID, 4)
        THEN UPDATE
            Set State_ID = @ProposalUserStateID,
                Last_Affected = GetDate()
    WHEN Not Matched THEN
        INSERT (Proposal_ID, Person_ID, Of_DMS_Interest, State_ID, Last_Affected)
        VALUES (source.Proposal_ID, source.PERSON_ID, source.Of_DMS_Interest, @ProposalUserStateID, GetDate())
    WHEN NOT MATCHED BY SOURCE AND target.Proposal_ID = @EUSPropID And IsNull(State_ID, 0) NOT IN (4) THEN
        -- User/proposal mapping is defined in T_EUS_Proposal_Users but not in #tempEUSUsers
        -- Change state to 5="No longer associated with proposal"
        UPDATE SET State_ID=5, Last_Affected = GetDate()
    ;
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    If @myError <> 0
    Begin
        Set @message = 'Error trying to add associations between users and proposal'
        RAISERROR (@msg, 11, 14)
    End

    END TRY
    BEGIN CATCH
        EXEC FormatErrorMessage @message output, @myError output

        -- rollback any open transactions
        IF (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;

        If @logErrors > 0
        Begin
            Exec PostLogEntry 'Error', @message, 'AddUpdateLCColumn'
        End
    END Catch

    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateEUSProposals] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateEUSProposals] TO [DMS_EUS_Admin] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateEUSProposals] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateEUSProposals] TO [Limited_Table_Write] AS [dbo]
GO
