/****** Object:  StoredProcedure [dbo].[UpdateInstrumentUsageReport] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[UpdateInstrumentUsageReport]
/****************************************************
**
**  Desc:  Update requested EMSL instument usage table from input XML list 
**
**  @factorList will look like this 
**
**      <id type="Seq" />
**      <r i="1939" f="Comment" v="..." />
**      <r i="1941" f="Comment" v="..." />
**      <r i="2058" f="Proposal" v="..." />
**      <r i="1941" f="Proposal" v="..." />
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**  Date:   10/07/2012 
**          10/09/2012 grk - Enabled 10 day edit cutoff and UpdateDatasetInterval for 'reload'
**          11/21/2012 mem - Extended cutoff for 'reload' to be 45 days instead of 10 days
**          01/09/2013 mem - Extended cutoff for 'reload' to be 90 days instead of 45 days
**          04/03/2013 grk - Made Usage editable
**          04/04/2013 grk - Clearing Usage on reload
**          02/23/2016 mem - Add set XACT_ABORT on
**          11/08/2016 mem - Use GetUserLoginWithoutDomain to obtain the user's network login
**          11/10/2016 mem - Pass '' to GetUserLoginWithoutDomain
**          04/11/2017 mem - Now using fields DMS_Inst_ID and Usage_Type in T_EMSL_Instrument_Usage_Report
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          05/03/2019 mem - Pass 0 to UpdateEMSLInstrumentUsageReport for @eusInstrumentID
**          09/10/2019 mem - Extended cutoff for 'update' to be 365 days instead of 90 days
**                         - Changed the cutoff for reload to 60 days
**    
** Pacific Northwest National Laboratory, Richland, WA
** Copyright 2009, Battelle Memorial Institute
*****************************************************/
(
    @factorList text,
    @operation varchar(32),        -- 'update', 'refresh', 'reload'
    @year VARCHAR(12),
    @month VARCHAR(12),
    @instrument VARCHAR(128),
    @message varchar(512) output,
    @callingUser varchar(128) = ''
)
As
    Set XACT_ABORT, nocount on
    Set CONCAT_NULL_YIELDS_NULL ON
    Set ANSI_PADDING ON

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Set @message = ''
     
    Declare @msg VARCHAR(512) 

    Declare @startOfMonth Datetime 
    Declare @startOfNextMonth Datetime
    Declare @endOfMonth Datetime
    Declare @lockDateReload Datetime
    Declare @lockDateUpdate Datetime

    Declare @xml AS xml

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------
        
    Declare @authorized tinyint = 0    
    Exec @authorized = VerifySPAuthorized 'UpdateInstrumentUsageReport', @raiseError = 1
    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;

    ---------------------------------------------------
     -- validate inputs
    ---------------------------------------------------
    
    If IsNull(@callingUser, '') = ''
        Set @callingUser = dbo.GetUserLoginWithoutDomain('')

    Declare @instrumentID int = 0
    
    Set @instrument = IsNull(@instrument, '')
    
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

    Set @operation = Ltrim(Rtrim(IsNull(@operation, '')))
    If Len(@operation) = 0
    Begin
        RAISERROR ('Operation must be defined', 11, 4)
    End

    Set @month = Ltrim(Rtrim(IsNull(@month, '')))
    Set @year  = Ltrim(Rtrim(IsNull(@year, '')))

    If Len(@month) = 0
    Begin
        RAISERROR ('Month must be defined', 11, 4)
    End

    If Len(@year) = 0
    Begin
        RAISERROR ('Year must be defined', 11, 4)
    End
    
    Declare @monthValue Int = Try_Cast(@month As Int)
    Declare @yearValue Int = Try_Cast(@year As Int)

    If @monthValue Is Null 
    Begin
        RAISERROR ('Month must be an integer, not: "%s"', 11, 4, @month)
    End

    If Len(@year) = 0
    Begin
        RAISERROR ('Year must be an integer, not: "%s"', 11, 4, @year)
    End

    -- Uncomment to debug
    -- Declare @debugMessage Varchar(1024) = 'Operation: ' + @operation + '; Instrument: ' + @instrument + '; ' + @year + '-' + @month + '; ' + Cast(@factorList As Varchar(1024))
    -- Exec PostLogEntry 'Debug', @debugMessage, 'UpdateInstrumentUsageReport'
    
    -----------------------------------------------------------
    -- Copy @factorList text variable into the XML variable
    -----------------------------------------------------------
    Set @xml = @factorList
    
    ---------------------------------------------------
    ---------------------------------------------------
    BEGIN TRY

        ---------------------------------------------------
        -- get boundary dates
        ---------------------------------------------------
        Set @startOfMonth = @month + '/1/' + @year                  -- Beginning of the month that we are updating
        Set @startOfNextMonth = DATEADD(MONTH, 1, @startOfMonth)    -- Beginning of the next month after @startOfMonth
        Set @endOfMonth = DATEADD(MINUTE, -1, @startOfNextMonth)    -- End of the month that we are editing
        Set @lockDateReload = DATEADD(DAY, 60, @startOfNextMonth)   -- Date threshold, afterwhich users can no longer reload this month's data
        Set @lockDateUpdate = DATEADD(DAY, 365, @startOfNextMonth)  -- Date threshold, afterwhich users can no longer update this month's data

        If @operation In ('update') And GETDATE() > @lockDateUpdate
            RAISERROR ('Changes are not allowed to instrument usage data over 365 days old', 11, 13)

        If Not @operation In ('update') And GETDATE() > @lockDateReload
            RAISERROR ('Instrument usage data over 60 days old cannot be reloaded or refreshed', 11, 13)

        -----------------------------------------------------------
        -- foundational actions for various operations
        -----------------------------------------------------------
              
        IF @operation in ('update')
        BEGIN --<a>        
        
            -----------------------------------------------------------
            -- temp table to hold update items
            -----------------------------------------------------------
            --
            CREATE TABLE #TMP (
                Identifier int null,
                Field varchar(128) null,
                Value varchar(128) null,
            )

            -----------------------------------------------------------
            -- populate temp table with new parameters
            -----------------------------------------------------------
            --
            INSERT INTO #TMP
                (Identifier, Field, Value)
            SELECT
                xmlNode.value('@i', 'int') Identifier,
                xmlNode.value('@f', 'nvarchar(256)') Field,
                xmlNode.value('@v', 'nvarchar(256)') Value
            FROM @xml.nodes('//r') AS R(xmlNode)
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount
            --
            if @myError <> 0
                RAISERROR ('Error trying to convert list', 11, 1)

            -----------------------------------------------------------
            -- make sure changed fields are allowed
            -----------------------------------------------------------
            
            Declare @badFields VARCHAR(4096) = ''
            SELECT DISTINCT @badFields = @badFields + Field + ',' FROM #TMP WHERE NOT Field IN ('Proposal', 'Operator', 'Comment', 'Users', 'Usage')
            --                                   
            IF @badFields <> ''        
                RAISERROR ('The following field(s) are not editable: %s', 11, 27, @badFields)

        END --<a>
  
        IF @operation in ('reload', 'refresh')
        BEGIN --<b>
            -----------------------------------------------------------
            -- validation    
            -----------------------------------------------------------
            
            IF @operation = 'reload' AND ISNULL(@instrument, '') = ''
                RAISERROR ('An instrument must be specified for the reload operation', 11, 10)
        
                    
            IF ISNULL(@year, '') = '' OR ISNULL(@month, '') = ''
                RAISERROR ('A year and month must be specified for this operation', 11, 11)

            IF ISNULL(@instrument, '') = '' 
            BEGIN 
                ---------------------------------------------------
                -- Get list of EMSL instruments
                ---------------------------------------------------
                --
                CREATE TABLE #Tmp_Instruments (
                    Seq INT IDENTITY(1,1) NOT NULL,
                    Instrument varchar(65)
                )
                INSERT INTO #Tmp_Instruments (Instrument)
                SELECT [Name]                                                                                      
                FROM V_Instrument_Tracked 
                WHERE ISNULL(EUS_Primary_Instrument, '') = 'Y'
            END                             
    
        END --<b>                        

        IF @operation = 'update'
        BEGIN
            UPDATE T_EMSL_Instrument_Usage_Report
            SET Comment = #TMP.Value
            FROM T_EMSL_Instrument_Usage_Report
            INNER JOIN #TMP ON Seq = Identifier
            WHERE Field = 'Comment'                        
        
            UPDATE T_EMSL_Instrument_Usage_Report
            SET Proposal = #TMP.Value
            FROM T_EMSL_Instrument_Usage_Report
            INNER JOIN #TMP ON Seq = Identifier
            WHERE Field = 'Proposal'                        

            UPDATE T_EMSL_Instrument_Usage_Report
            SET Operator = #TMP.Value
            FROM T_EMSL_Instrument_Usage_Report
            INNER JOIN #TMP ON Seq = Identifier
            WHERE Field = 'Operator'                        

            UPDATE T_EMSL_Instrument_Usage_Report
            SET Users = #TMP.Value
            FROM T_EMSL_Instrument_Usage_Report
            INNER JOIN #TMP ON Seq = Identifier
            WHERE Field = 'Users'

            UPDATE T_EMSL_Instrument_Usage_Report
            SET Usage_Type = InstUsageType.ID
            FROM T_EMSL_Instrument_Usage_Report InstUsage
                 INNER JOIN #TMP
                   ON InstUsage.Seq = #TMP.Identifier
                 INNER JOIN T_EMSL_Instrument_Usage_Type InstUsageType
                   ON #TMP.VALUE = InstUsageType.Name
            WHERE Field = 'Usage'
            
            UPDATE T_EMSL_Instrument_Usage_Report
            SET 
                Updated = GETDATE(),
                UpdatedBy = @callingUser        
            FROM T_EMSL_Instrument_Usage_Report
            INNER JOIN #TMP ON Seq = Identifier

        END 

        IF @operation = 'reload'
        BEGIN        
            UPDATE T_EMSL_Instrument_Usage_Report
            SET 
                Usage_Type = Null,
                Proposal = '',
                Users = '',
                Operator = '',
                Comment = ''
            WHERE @year = [Year]
            AND @month = [Month]
            AND (@instrument = '' OR DMS_Inst_ID = @instrumentID)

            EXEC UpdateDatasetInterval @instrument, @startOfMonth, @endOfMonth, @message output
    
            SET @operation = 'refresh'            
        END 

        IF @operation = 'refresh'
        BEGIN
            IF Len(ISNULL(@instrument, '')) > 0
            BEGIN                     
                EXEC @myError = UpdateEMSLInstrumentUsageReport @instrument, 0, @endOfMonth, @msg output
                IF(@myError <> 0)          
                    RAISERROR (@msg, 11, 6)
            END
            ELSE 
            BEGIN --<m>
                Declare @inst VARCHAR(64)
                Declare @index INT = 0
                Declare @done TINYINT = 0

                WHILE @done = 0
                BEGIN --<x>
                    SET @inst = NULL 
                    SELECT TOP 1 @inst = Instrument
                    FROM #Tmp_Instruments 
                    WHERE Seq > @index
            
                    SET @index = @index + 1
            
                    IF @inst IS NULL 
                    BEGIN 
                        SET @done = 1
                    END 
                    ELSE 
                    BEGIN --<y>
                        EXEC UpdateEMSLInstrumentUsageReport @inst, 0, @endOfMonth, @msg output
                    END  --<y>
                END --<x>
            END --<m>                                                    
        END 

    END TRY
    BEGIN CATCH 
        EXEC FormatErrorMessage @message output, @myError output
        
        -- rollback any open transactions
        IF (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;
    END CATCH
    return @myError


GO
GRANT VIEW DEFINITION ON [dbo].[UpdateInstrumentUsageReport] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[UpdateInstrumentUsageReport] TO [DMS_SP_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[UpdateInstrumentUsageReport] TO [DMS2_SP_User] AS [dbo]
GO
