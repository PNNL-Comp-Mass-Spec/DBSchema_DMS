/****** Object:  StoredProcedure [dbo].[UpdateDatasetInterval] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[UpdateDatasetInterval]
/****************************************************
**
**  Desc: 
**      Updates dataset interval and creates entries 
**      for long intervals in the intervals table 
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**  Date:   02/08/2012 
**          02/10/2012 mem - Now updating Acq_Length_Minutes in T_Dataset
**          02/13/2012 grk - Raised @maxNormalInterval to ninety minutes
**          02/15/2012 mem - No longer updating Acq_Length_Minutes in T_Dataset since now a computed column
**          03/07/2012 mem - Added parameter @infoOnly
**                         - Now validating @instrumentName
**          03/29/2012 grk - interval values in T_Run_Interval were not being updated
**          04/10/2012 grk - now deleting "short" long intervals
**          06/08/2012 grk - added lookup for @maxNormalInterval
**          08/30/2012 grk - extended dataset update to include beginning of next month
**          11/19/2013 mem - Now updating Interval_to_Next_DS in T_Dataset only if the newly computed interval differs from the stored interval
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          05/03/2019 mem - Use EUS_Instrument_ID for DMS instruments that share a single eusInstrumentId
**    
*****************************************************/
(
    @instrumentName varchar(64),
    @startDate datetime,
    @endDate datetime,
    @message varchar(512) = '' output,
    @infoOnly tinyint = 0
)
AS
    Set XACT_ABORT, nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    set @message = ''
    Set @infoOnly = IsNull(@infoOnly, 0)
    
    Declare @maxNormalInterval int = dbo.GetLongIntervalThreshold()

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------
        
    Declare @authorized tinyint = 0    
    Exec @authorized = VerifySPAuthorized 'UpdateDatasetInterval', @raiseError = 1
    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;
    
    BEGIN TRY 

        ---------------------------------------------------
        -- Make sure @instrumentName is valid (and is properly capitalized)
        ---------------------------------------------------

        Declare @instrumentNameMatch varchar(128) = ''
        Declare @eusInstrumentId Int = 0

        SELECT @instrumentNameMatch = IN_Name
        FROM T_Instrument_Name
        WHERE IN_Name = @instrumentName
        
        If IsNull(@instrumentNameMatch, '') = ''
        Begin
            Set @message = 'Unknown instrument: ' + @instrumentName
            If @infoOnly <> 0
                Print @message
        
            return 0
        End
        Else
        Begin
            Set @instrumentName = @instrumentNameMatch
        End

        ---------------------------------------------------
        -- Temp table to hold time information about datasets
        ---------------------------------------------------
        --
        CREATE TABLE #Tmp_Durations (
            Seq INT primary KEY IDENTITY(1,1) NOT NULL,
            Dataset_ID INT ,
            Dataset VARCHAR(128) ,
            Instrument VARCHAR(128),
            Time_Start DATETIME ,
            Time_End DATETIME,
            Duration int,                -- Duration of run, in minutes
            [Interval] INT NULL
        )
                
        ---------------------------------------------------
        -- Auto switch to @eusInstrumentId if needed
        ---------------------------------------------------

        SELECT @eusInstrumentId = InstMapping.EUS_Instrument_ID
        FROM T_Instrument_Name InstName
             INNER JOIN T_EMSL_DMS_Instrument_Mapping InstMapping
               ON InstName.Instrument_ID = InstMapping.DMS_Instrument_ID
             INNER JOIN ( SELECT EUS_Instrument_ID
                          FROM T_Instrument_Name InstName
                               INNER JOIN T_EMSL_DMS_Instrument_Mapping InstMapping
                                 ON InstName.Instrument_ID = InstMapping.DMS_Instrument_ID
                          GROUP BY EUS_Instrument_ID
                          HAVING Count(*) > 1 ) LookupQ
               ON InstMapping.EUS_Instrument_ID = LookupQ.EUS_Instrument_ID
        WHERE InstName.IN_name = @instrumentName
            
        If @eusInstrumentId > 0
        Begin
            INSERT INTO #Tmp_Durations (
                Dataset_ID ,
                Dataset ,
                Instrument,
                Time_Start ,
                Time_End ,
                Duration
            )
            SELECT DS.Dataset_ID,
                   DS.Dataset_Num,
                   InstName.IN_name,
                   DS.Acq_Time_Start,
                   DS.Acq_Time_End,
                   DATEDIFF(MINUTE, DS.Acq_Time_Start, DS.Acq_Time_End)
            FROM T_Dataset DS
                 INNER JOIN T_Instrument_Name InstName
                   ON DS.DS_instrument_name_ID = InstName.Instrument_ID
                 INNER JOIN T_EMSL_DMS_Instrument_Mapping InstMapping
                   ON InstName.Instrument_ID = InstMapping.DMS_Instrument_ID
            WHERE @startDate <= DS.Acq_Time_Start AND
                  DS.Acq_Time_Start <= @endDate AND
                  InstMapping.EUS_Instrument_ID = @eusInstrumentId
            ORDER BY DS.Acq_Time_Start

        End
        Else
        Begin
            INSERT INTO #Tmp_Durations (
                Dataset_ID ,
                Dataset ,
                Instrument,
                Time_Start ,
                Time_End ,
                Duration
            )
            SELECT DS.Dataset_ID,
                   DS.Dataset_Num,
                   InstName.IN_name,
                   DS.Acq_Time_Start,
                   DS.Acq_Time_End,
                   DATEDIFF(minute, DS.Acq_Time_Start, DS.Acq_Time_End)
            FROM T_Dataset DS
                 INNER JOIN T_Instrument_Name InstName
                   ON DS.DS_instrument_name_ID = InstName.Instrument_ID
            WHERE @startDate <= DS.Acq_Time_Start AND
                  DS.Acq_Time_Start <= @endDate AND
                  InstName.IN_name = @instrumentName

            ORDER BY DS.Acq_Time_Start
        End

        ---------------------------------------------------
        -- Calculate inter-run intervals and update temp table
        ---------------------------------------------------

        Declare @maxSeq Int

        SELECT @maxSeq = MAX(Seq) 
        FROM #Tmp_Durations

        Declare @start DATETIME, @end DATETIME, @interval INT 
        Declare @index INT = 1
        Declare @seqIncrement INT = 1

        WHILE @index < @maxSeq
        BEGIN
            SET @start = NULL
            SET @end = NULL 

            SELECT @start = Time_Start
            FROM #Tmp_Durations
            WHERE Seq = @index + @seqIncrement

            SELECT @end = Time_End
            FROM #Tmp_Durations
            WHERE Seq = @index

            SET @interval = CASE
                                WHEN @start <= @end THEN 0
                                ELSE ISNULL(DATEDIFF(MINUTE, @end, @start), 0)
                            END
            
            -- Make sure that start and end times are not null
            --
            IF (NOT @start IS NULL) AND (NOT @end IS NULL)
            BEGIN 
                UPDATE #Tmp_Durations
                SET [Interval] = ISNULL(@interval, 0)
                WHERE Seq = @index
            END 

            SET @index = @index + @seqIncrement
        END

        If @infoOnly > 0
        Begin

            ---------------------------------------------------
            -- Preview dataset intervals
            ---------------------------------------------------

            SELECT InstName.IN_name AS Instrument,
                   DS.Dataset_Num AS Dataset,
                   DS.Dataset_ID,
                   DS.DS_Created,
                   DS.Acq_Time_Start,
                   #Tmp_Durations.[Interval] AS Interval_to_Next_DS,
                   CASE
                       WHEN [Interval] > @maxNormalInterval THEN 'Yes'
                       ELSE ''
                   END AS Long_Interval
            FROM T_Dataset DS
                 INNER JOIN #Tmp_Durations
                   ON DS.Dataset_ID = #Tmp_Durations.Dataset_ID
                 INNER JOIN T_Instrument_Name InstName
                   ON DS.DS_instrument_name_ID = InstName.Instrument_ID
            ORDER BY CASE
                         WHEN [Interval] > @maxNormalInterval THEN 0
                         ELSE 1
                     END, DS.Dataset_ID
        End
        Else
        Begin
        
            ---------------------------------------------------
            -- Start a transaction
            ---------------------------------------------------
        
            Declare @transName varchar(32) = 'UpdateDatasetInterval'

            BEGIN TRANSACTION @transName

            ---------------------------------------------------
            -- Update intervals in dataset table
            ---------------------------------------------------
            
            UPDATE DS
            SET Interval_to_Next_DS = #Tmp_Durations.[Interval]
            FROM T_Dataset DS
                 INNER JOIN #Tmp_Durations
                   ON DS.Dataset_ID = #Tmp_Durations.Dataset_ID
            WHERE IsNull(DS.Interval_to_Next_DS, 0) <> Coalesce(#Tmp_Durations.[Interval], DS.Interval_to_Next_DS, 0)

            ---------------------------------------------------
            -- Update intervals in long interval table
            ---------------------------------------------------

            UPDATE dbo.T_Run_Interval
            SET [Interval] = #Tmp_Durations.[Interval]
            FROM dbo.T_Run_Interval target
                 INNER JOIN #Tmp_Durations
                   ON target.ID = #TMP_Durations.Dataset_ID
            WHERE IsNull(target.[Interval], 0) <> Coalesce(#Tmp_Durations.[Interval], target.[Interval], 0)

            ---------------------------------------------------
            -- Make entries in interval tracking table
            -- for long intervals
            ---------------------------------------------------

            INSERT INTO T_Run_Interval( ID,
                                        Instrument,
                                        Start,
                                        [Interval] )
            SELECT #Tmp_Durations.Dataset_ID,
                   InstName.IN_Name,
                   #Tmp_Durations.Time_End,
                   #Tmp_Durations.[Interval]
            FROM T_Dataset DS
                 INNER JOIN #Tmp_Durations
                   ON DS.Dataset_ID = #Tmp_Durations.Dataset_ID
                 INNER JOIN T_Instrument_Name InstName
                   ON DS.DS_instrument_name_ID = InstName.Instrument_ID
            WHERE NOT #Tmp_Durations.Dataset_ID IN ( SELECT ID FROM T_Run_Interval ) AND
                  #Tmp_Durations.[Interval] > @maxNormalInterval
                  
            ---------------------------------------------------
            -- Delete "short" long intervals
            -- (intervals that are less than threshold)
            ---------------------------------------------------
            
            DELETE FROM T_Run_Interval
            WHERE (Interval < @maxNormalInterval)
                  
            COMMIT TRANSACTION @transName
        End
        
    END TRY
    BEGIN CATCH 
        EXEC FormatErrorMessage @message output, @myError output
        
        -- rollback any open transactions
        IF (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;
            
        Exec PostLogEntry 'Error', @message, 'UpdateDatasetInterval'
    END CATCH
    
    If @infoOnly <> 0 and @myError <> 0
        Print @message

    RETURN @myError

GO
GRANT VIEW DEFINITION ON [dbo].[UpdateDatasetInterval] TO [DDL_Viewer] AS [dbo]
GO
