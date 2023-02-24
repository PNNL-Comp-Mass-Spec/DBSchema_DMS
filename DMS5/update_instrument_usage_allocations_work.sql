/****** Object:  StoredProcedure [dbo].[UpdateInstrumentUsageAllocationsWork] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[UpdateInstrumentUsageAllocationsWork]
/****************************************************
**
**  Desc:
**      Update requested instrument usage allocation using data in #T_OPS
**
**      CREATE TABLE #T_OPS (
**          Entry_ID int Identity(1,1),
**          Allocation varchar(128) NULL,
**          InstGroup varchar(128) null,
**          Proposal varchar(128) null,
**          Comment varchar(256) null,
**          FY int,
**          Operation CHAR(1) NULL -- 'i' -> increment, 'd' -> decrement, anything else -> set
**      )
**
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**  Auth:   grk
**  Date:   03/30/2012 mem - Factored out of UpdateInstrumentAllocations
**          03/31/2012 mem - Updated Merge statement to not enter new rows if the allocation hours are 0 and comment is empty
**          11/08/2016 mem - Use GetUserLoginWithoutDomain to obtain the user's network login
**          11/10/2016 mem - Pass '' to GetUserLoginWithoutDomain
**
*****************************************************/
(
    @fy int,
    @message varchar(512) OUTPUT,
    @callingUser varchar(128) = '',
    @infoOnly tinyint = 0                   -- Set to 1 to preview the changes that would be made
)
AS
    SET NOCOUNT ON

    declare @myError int
    declare @myRowCount int
    set @myError = 0
    set @myRowCount = 0

    -----------------------------------------------------------
    -- Validate the inputs
    -----------------------------------------------------------

    SET @message = ''

    If IsNull(@callingUser, '') = ''
        SET @callingUser = dbo.GetUserLoginWithoutDomain('')

    Set @infoOnly = IsNull(@infoOnly, 0)

    IF @infoOnly > 0
    BEGIN
        SELECT * FROM #T_OPS
    END
    ELSE
    BEGIN -- <a>
        -----------------------------------------------------------
        -- perform necessary inserts
        -- and set/increment/decrement operations for updates
        -----------------------------------------------------------

        ---------------------------------------------------
        -- transaction
        ---------------------------------------------------
        --
        declare @transName varchar(32)
        set @transName = 'UpdateInstrumentUsageAllocations'

        begin transaction @transName


        MERGE T_Instrument_Allocation AS Target
        USING (
                SELECT Proposal, InstGroup,  Allocation, Comment, FY, Operation
                FROM #T_OPS
                ) AS Source (Proposal, InstGroup,  Allocation, Comment, FY, Operation)
            ON Source.Proposal = Target.Proposal_ID
            AND Source.InstGroup = Target.Allocation_Tag
            AND Source.FY = Target.Fiscal_Year
        WHEN MATCHED THEN
            UPDATE SET Allocated_Hours = CASE
                                            WHEN Source.Operation = 'i' THEN Allocated_Hours + Source.Allocation
                                            WHEN Source.Operation = 'd' THEN Allocated_Hours - Source.Allocation
                                            ELSE Allocation
                                            END,
                        Comment = Source.Comment,
                        Last_Affected = CASE WHEN IsNull(Source.Operation, '') <> '' Then GetDate()
                                             ELSE CASE WHEN IsNull(Allocated_Hours, -1) <> IsNull(Allocation, -1) THEN GetDate()
                                                       ELSE Last_Affected
                                                       END
                                             END
        WHEN NOT MATCHED BY TARGET And
             (IsNull(Source.Allocation, 0) <> 0 Or
              IsNull(Source.Comment, '') <> '') THEN
            INSERT ( Allocation_Tag ,
                        Proposal_ID ,
                        Allocated_Hours ,
                        Comment ,
                        Fiscal_Year
                    )
            VALUES  ( Source.InstGroup ,
                        Source.Proposal ,
                        Source.Allocation ,
                        Source.Comment ,
                        Source.FY
                    );

        ---------------------------------------------------
        ---------------------------------------------------
        commit transaction @transName


        -- If @callingUser is defined, then update Entered_By in T_Instrument_Allocation_Updates
        If Len(@callingUser) > 0
        Begin -- <b>

            ------------------------------------------------
            -- Call AlterEnteredByUser for each entry in #T_OPS
            ------------------------------------------------

            Declare @EntryID int = 0
            Declare @TargetEntryID int
            Declare @Proposal varchar(128)
            Declare @InstGroup varchar(128)

            Declare @CurrentTime datetime
            Set @CurrentTime = GetDate()

            Declare @CountUpdated int = 0
            Declare @Continue int = 1
            Declare @MatchIndex int
            Declare @EnteredBy varchar(256)
            Declare @EnteredByNew varchar(256)

            While @Continue = 1
            Begin -- <c>
                SELECT TOP 1 @EntryID = Entry_ID,
                                @Proposal = Proposal,
                                @InstGroup = InstGroup
                FROM #T_OPS
                WHERE Entry_ID > @EntryID
                ORDER BY Entry_ID
                --
                SELECT @myError = @@error, @myRowCount = @@rowcount

                If @myRowCount = 0
                    Set @continue = 0
                Else
                Begin -- <d>
                    Set @TargetEntryID = 0

                    SELECT @TargetEntryID = Entry_ID,
                            @EnteredBy = Entered_By
                    FROM T_Instrument_Allocation_Updates
                    WHERE Allocation_Tag = @InstGroup AND
                            Proposal_ID = @Proposal AND
                            Fiscal_Year = @fy AND
                            Entered BETWEEN DateAdd(SECOND, - 15, @CurrentTime) AND DateAdd(SECOND, 1, @CurrentTime)
                    --
                    SELECT @myError = @@error, @myRowCount = @@rowcount


                    If @myRowCount > 0
                    Begin -- <e>
                        -- Confirm that @EnteredBy doesn't already contain @CallingUser
                        -- If it does, then there's no need to update it

                        Set @MatchIndex = CharIndex(@CallingUser, @EnteredBy)

                        If @MatchIndex <= 0
                        Begin -- <f>
                            -- Need to update Entered_By
                            -- Look for a semicolon in @EnteredBy

                            Set @MatchIndex = CharIndex(';', @EnteredBy)

                            If @MatchIndex > 0
                                Set @EnteredByNew = @CallingUser + ' (via ' + SubString(@EnteredBy, 1, @MatchIndex-1) + ')' + SubString(@EnteredBy, @MatchIndex, Len(@EnteredBy))
                            Else
                                Set @EnteredByNew = @CallingUser + ' (via ' + @EnteredBy + ')'

                            If Len(IsNull(@EnteredByNew, '')) > 0
                            Begin
                                UPDATE T_Instrument_Allocation_Updates
                                SET Entered_By = @EnteredByNew
                                WHERE Entry_ID = @TargetEntryID
                            End

                        End -- </f>
                    End -- </e>
                End -- </d>
            End -- </c>
        End -- </b>

    END -- </a>

    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[UpdateInstrumentUsageAllocationsWork] TO [DDL_Viewer] AS [dbo]
GO
