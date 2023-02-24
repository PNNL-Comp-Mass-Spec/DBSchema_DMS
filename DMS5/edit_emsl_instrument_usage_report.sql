/****** Object:  StoredProcedure [dbo].[edit_emsl_instrument_usage_report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[edit_emsl_instrument_usage_report]
/****************************************************
**
**  Desc:
**      Updates selected EMSL instrument usage report items
**
**      This procedure appears to be unused in 2017
**
**  Parameters:
**
**  Auth:   grk
**  Date:   08/31/2012 grk - Initial release
**          09/11/2012 grk - fixed update SQL
**          04/11/2017 mem - Replace column Usage with Usage_Type
**          07/15/2022 mem - Instrument operator ID is now tracked as an actual integer
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @year int = 2012 ,
    @month int = 8 ,
    @instrument varchar(64) = '',
    @type varchar(32) = '',
    @usage varchar(32) = '',
    @proposal varchar(32) = '',
    @users varchar(512) = '',
    @operator varchar(32) = '',     -- Operator for update (should be an integer representing EUS Person ID; if an empty string, will store NULL for the operator ID)
    @comment varchar(512) = '',
    @fieldName varchar(32) = '' ,   -- Proposal, Usage,  Users,  Operator,  Comment,
    @newValue varchar(512) = '',
    @doUpdate TINYINT = 0
)
AS
    SET NOCOUNT ON

    Declare @myError int
    Declare @myRowCount int
    Set @myError = 0
    Set @myRowCount = 0

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    Set @Month = IsNull(@Month, 0)
    Set @Year = IsNull(@Year, 0)

    Set @Instrument = IsNull(@Instrument, '')
    Set @Type = IsNull(@Type, '')
    Set @Usage = IsNull(@Usage, '')
    Set @Proposal = IsNull(@Proposal, '')
    Set @Users = IsNull(@Users, '')

    -- Assure that @Operator is either an integer or null
    Set @Operator = Try_Convert(int, @Operator)

    Set @NewValue = IsNull(@NewValue, '')

    Declare @instrumentID int = 0
    Declare @usageTypeID tinyint = 0

    If @Instrument <> ''
    Begin
        SELECT @instrumentID = Instrument_ID
        FROM T_Instrument_Name
        WHERE IN_name = @Instrument
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @instrumentID = 0
        Begin
            RAISERROR ('Instrument not found: "%s"', 11, 4, @Instrument)
        End
    End

    If @Usage <> ''
    Begin
        SELECT @usageTypeID = ID
        FROM T_EMSL_Instrument_Usage_Type
        WHERE [Name] = @Usage
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @usageTypeID = 0
        Begin
            RAISERROR ('Usage type not found: "%s"', 11, 4, @Usage)
        End
    End

    ---------------------------------------------------
    -- Temp table to hold keys to affected items
    ---------------------------------------------------

    CREATE TABLE #TX (
        Seq int
    )

    ---------------------------------------------------
    -- Get keys to affected items
    ---------------------------------------------------

    INSERT INTO #TX ( Seq )
    SELECT  Seq
    FROM    T_EMSL_Instrument_Usage_Report
    WHERE   ( Month = @Month )
            AND ( Year = @Year )
            AND (( @instrumentID = 0 ) OR ( DMS_Inst_ID = @instrumentID ))
            AND (( @Type = '' ) OR ( Type = @Type ))
            AND (( @usageTypeID = 0 ) OR ( Usage_Type = @usageTypeID ))
            AND (( @Proposal = '' ) OR ( Proposal = @Proposal ))
            AND (( @Users = '' ) OR ( Users = @Users ))
            AND (( @Operator Is Null ) OR ( Operator = @Operator ))

    ---------------------------------------------------
    -- Display affected items or make change
    ---------------------------------------------------

    IF @DoUpdate = 0
    BEGIN
        SELECT *
        FROM #TX INNER JOIN dbo.T_EMSL_Instrument_Usage_Report TD ON #TX.Seq = TD.Seq
    END
    ELSE
        BEGIN

        IF @FieldName = 'Proposal'
        BEGIN
            UPDATE TD
            SET Proposal = @NewValue
            FROM T_EMSL_Instrument_Usage_Report TD INNER JOIN #TX ON #TX.Seq = TD.Seq
        END

        IF @FieldName = 'Usage'
        BEGIN
            If @NewValue <> ''
            Begin
                Declare @newUsageTypeID tinyint = 0

                SELECT @newUsageTypeID = ID
                FROM T_EMSL_Instrument_Usage_Type
                WHERE [Name] = @NewValue
                --
                SELECT @myError = @@error, @myRowCount = @@rowcount

                If @myRowCount = 0 Or @newUsageTypeID = 0
                Begin
                    RAISERROR ('Invalid usage type: "%s"', 11, 4, @NewValue)
                End
                Else
                Begin
                    UPDATE TD
                    SET Usage_Type = @newUsageTypeID
                    FROM T_EMSL_Instrument_Usage_Report TD INNER JOIN #TX ON #TX.Seq = TD.Seq
                End
            End
        END

        IF @FieldName = 'Users'
        BEGIN
            UPDATE TD
            SET Users = @NewValue
            FROM T_EMSL_Instrument_Usage_Report TD INNER JOIN #TX ON #TX.Seq = TD.Seq
        END

        IF @FieldName = 'Operator'
        BEGIN
            -- Store null if @NewValue is not an integer
            UPDATE TD
            SET Operator = Try_Convert(int, @NewValue)
            FROM T_EMSL_Instrument_Usage_Report TD INNER JOIN #TX ON #TX.Seq = TD.Seq
        END

        IF @FieldName = 'Comment'
        BEGIN
            UPDATE TD
            SET Comment = @NewValue
            FROM T_EMSL_Instrument_Usage_Report TD INNER JOIN #TX ON #TX.Seq = TD.Seq
        END
    END

    ---------------------------------------------------
    --
    ---------------------------------------------------

    DROP TABLE #TX
    RETURN

GO
GRANT VIEW DEFINITION ON [dbo].[edit_emsl_instrument_usage_report] TO [DDL_Viewer] AS [dbo]
GO
