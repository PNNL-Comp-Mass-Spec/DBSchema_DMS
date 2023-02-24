/****** Object:  StoredProcedure [dbo].[PopulateInstrumentFilterTable] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure [dbo].[PopulateInstrumentFilterTable]
/****************************************************
** 
**  Desc:   Populates temp table #Tmp_InstrumentFilter 
**          based on the comma-separated instrument names in @instrumentFilterList
**
**  The calling procedure must create the temporary table:
**    CREATE TABLE #Tmp_InstrumentFilter (
**        Instrument_ID int NOT NULL
**    )
**        
**  Return values: 0: success, otherwise, error code
** 
**  Date:   07/22/2019 mem - Initial version
**    
*****************************************************/
(
    @instrumentFilterList varchar(2000) = '',   -- Comma separated list of instrument names (% and * wild cards are allowed)
    @message varchar(512) = '' output
)
As
    Set nocount on
    
    Declare @myError int = 0
    Declare @myRowCount int = 0

    Declare @msg varchar(512)

    Set @instrumentFilterList = Ltrim(Rtrim(IsNull(@instrumentFilterList, '')))
    Set @message = ''

    If @instrumentFilterList <> ''
    Begin
        
        CREATE TABLE #Tmp_MatchSpec (
            Match_Spec_ID int NOT NULL identity(1,1),
            Match_Spec varchar(2048)
        )
        
        INSERT INTO #Tmp_MatchSpec (Match_Spec)
        SELECT DISTINCT Value
        FROM dbo.udfParseDelimitedList(@instrumentFilterList, ',', 'PopulateInstrumentFilterTable')
        ORDER BY Value

        Declare @matchSpecID int = 0
        Declare @matchSpec varchar(2048)
        
        While @matchSpecID >= 0
        Begin
            SELECT TOP 1 @matchSpecID = Match_Spec_ID,
                         @matchSpec = Match_Spec
            FROM #Tmp_MatchSpec
            WHERE Match_Spec_ID > @matchSpecID
            ORDER BY Match_Spec_ID
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            If @myRowCount = 0
            Begin
                Set @matchSpecID = -1
            End
            Else
            Begin
                Set @matchSpec = Replace(@matchSpec, '*', '%')
                
                If CharIndex('%', @matchSpec) > 0
                Begin
                    INSERT INTO #Tmp_InstrumentFilter( Instrument_ID )
                    SELECT FilterQ.Instrument_ID
                    FROM ( SELECT Instrument_ID
                           FROM T_Instrument_Name
                           WHERE IN_name LIKE @matchSpec ) FilterQ
                         LEFT OUTER JOIN #Tmp_InstrumentFilter Target
                           ON FilterQ.Instrument_ID = Target.Instrument_ID
                    WHERE Target.Instrument_ID IS NULL
                    --
                    SELECT @myError = @@error, @myRowCount = @@rowcount
                End
                Else
                Begin
                    INSERT INTO #Tmp_InstrumentFilter( Instrument_ID )
                    SELECT FilterQ.Instrument_ID
                    FROM ( SELECT Instrument_ID
                           FROM T_Instrument_Name
                           WHERE IN_name = @matchSpec ) FilterQ
                         LEFT OUTER JOIN #Tmp_InstrumentFilter Target
                           ON FilterQ.Instrument_ID = Target.Instrument_ID
                    WHERE Target.Instrument_ID IS NULL
                    --
                    SELECT @myError = @@error, @myRowCount = @@rowcount
                End
            End
        End
        
    End
    Else
    Begin
        INSERT INTO #Tmp_InstrumentFilter( Instrument_ID )
        SELECT DISTINCT Instrument_ID
        FROM T_Instrument_Name
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
    End

    -----------------------------------------------------------
    -- Exit
    -----------------------------------------------------------
Done:
    return @myError

GO
