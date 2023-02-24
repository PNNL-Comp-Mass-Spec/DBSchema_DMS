/****** Object:  UserDefinedFunction [dbo].[GetRunTrackingMonthlyInfoByID] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[GetRunTrackingMonthlyInfoByID]
/****************************************************
**
**  Desc:   Returns run tracking information for given EUS Instrument ID
**          Modeled after GetRunTrackingMonthlyInfo
**    
**  Auth:   mem
**  Date:   02/14/2012 mem - Initial release
**          04/27/2020 mem - Update data validation checks
**                         - Make several columns in the output table nullable
**    
*****************************************************/
(
    @eusInstrumentId Int,
    @year varchar(8), -- '2012'
    @month varchar(12), -- '1'
    @options varchar(32) = ''       -- Reserved for future use
)
RETURNS @TX TABLE (
    Seq INT primary key,
    ID INT NULL,
    Dataset varchar(128) ,
    [Day] INT NULL,
    Duration int NULL,
    Interval INT NULL,
    Time_Start datetime NULL,
    Time_End datetime NULL,
    Instrument varchar(128) NULL,
    CommentState varchar(24) NULL,
    Comment varchar(256) NULL
)
AS
    BEGIN
        Declare @maxNormalInterval INT = dbo.GetLongIntervalThreshold()
        Declare @message varchar(512) = ''
    
        ---------------------------------------------------
        -- check arguments
        ---------------------------------------------------

        IF ISNULL(@year, 0) = 0 OR ISNULL(@month, 0) = 0 OR ISNULL(@eusInstrumentId, 0) = 0
        BEGIN
            INSERT INTO @TX (Seq, Dataset) VALUES (1, 'Bad arguments')
            RETURN 
        END

        ---------------------------------------------------
        -- Validate @eusInstrumentId
        ---------------------------------------------------

        Declare @instrumentIDFirst Int

        SELECT Top 1 @instrumentIDFirst = InstName.Instrument_ID
        FROM T_Instrument_Name AS InstName
             INNER JOIN T_EMSL_DMS_Instrument_Mapping AS InstMapping
               ON InstName.Instrument_ID = InstMapping.DMS_Instrument_ID
        WHERE InstMapping.EUS_Instrument_ID = @eusInstrumentId
        Order By InstName.IN_name

        IF ISNULL(@instrumentIDFirst, 0) = 0
        BEGIN
            INSERT INTO @TX (Seq, Dataset) VALUES (1, 'Unrecognized EUS ID; no DMS instruments are mapped to EUS Instrument ID ' + Cast(@eusInstrumentId As Varchar(12)))
            RETURN 
        END

        ---------------------------------------------------
        -- Set up dates for beginning and end of month 
        ---------------------------------------------------
        
        Declare @startDate varchar(16) = @month + '/1/' + @year
        Declare @firstDayOfStartingMonth datetime = CONVERT(datetime, @startDate, 102);
        Declare @firstDayOfTrailingMonth datetime = DATEADD(MONTH, 1, @firstDayOfStartingMonth)

        ---------------------------------------------------
        -- Get datasets whose start time falls within month 
        ---------------------------------------------------
        Declare @seqIncrement INT = 1
        Declare @seqOffset INT = 0

        INSERT INTO @TX
        (
            Seq,
            ID ,
            Dataset ,
            [Day],
            Time_Start ,
            Time_End ,
            Duration,
            [Interval],
            Instrument
        )        
        SELECT (@seqIncrement * ((ROW_NUMBER() OVER ( ORDER BY TD.Acq_Time_Start ASC )) - 1) + 1) + @seqOffset AS 'Seq',
               TD.Dataset_ID AS ID,
               TD.Dataset_Num AS Dataset,
               DATEPART(DAY, TD.Acq_Time_Start) AS [Day],
               TD.Acq_Time_Start AS Time_Start,
               TD.Acq_Time_End AS Time_End,
               TD.Acq_Length_Minutes AS Duration,
               TD.Interval_to_Next_DS AS [Interval],
               @instrumentIDFirst AS Instrument
        FROM T_Dataset AS TD
             INNER JOIN T_EMSL_DMS_Instrument_Mapping AS InstMapping
               ON TD.DS_instrument_name_ID = InstMapping.DMS_Instrument_ID
        WHERE InstMapping.EUS_Instrument_ID = @eusInstrumentId AND
              @firstDayOfStartingMonth <= TD.Acq_Time_Start AND
              TD.Acq_Time_Start < @firstDayOfTrailingMonth
        ORDER BY TD.Acq_Time_Start

        ---------------------------------------------------
        -- Need to add some part of run or interval from
        -- preceding month if first run in month is not
        -- close to beginning of month
        ---------------------------------------------------

        Declare @firstRunSeq int
        Declare @lastRunSeq int
        SELECT @firstRunSeq = MIN(Seq), @lastRunSeq = MAX(Seq) FROM @TX
        
        Declare @firstStart datetime
        SELECT @firstStart = Time_Start FROM @TX WHERE Seq = @firstRunSeq
        
        Declare @initialGap INT = DATEDIFF(MINUTE, @firstDayOfStartingMonth, @firstStart)
        
        -- get preceeding dataset (latest with starting time preceding this month)
        --
        IF DATEDIFF(MINUTE, @firstDayOfStartingMonth, @firstStart) > @maxNormalInterval
        BEGIN 
            Declare @precID INT
            Declare @precDataset varchar(128) 
            Declare @precStart datetime
            Declare @precEnd datetime 
            Declare @precDuration INT
            Declare @precInterval INT 

            SELECT TOP 1 @precID = TD.Dataset_ID,
                         @precDataset = TD.Dataset_Num,
                         @precStart = TD.Acq_Time_Start,
                         @precEnd = TD.Acq_Time_End,
                         @precDuration = TD.Acq_Length_Minutes,
                         @precInterval = TD.Interval_to_Next_DS
            FROM T_Dataset AS TD
                 INNER JOIN T_EMSL_DMS_Instrument_Mapping AS InstMapping
                   ON TD.DS_instrument_name_ID = InstMapping.DMS_Instrument_ID
            WHERE InstMapping.EUS_Instrument_ID = @eusInstrumentId AND
                  TD.Acq_Time_Start < @firstDayOfStartingMonth AND
                  TD.Acq_Time_Start > DATEADD(DAY, -90, @firstDayOfStartingMonth)
            ORDER BY TD.Acq_Time_Start DESC
            
            -- if preceeding dataset's end time is before start of month, 
            -- zero the duration and truncate the interval
            -- othewise just truncate the duration
            --
            IF @precEnd < @firstDayOfStartingMonth
            BEGIN 
                Set @precDuration = 0
                Set @precInterval = @initialGap
            END
            ELSE
            BEGIN 
                Set @precDuration = DATEDIFF(MINUTE, @firstDayOfStartingMonth, @precStart)
            END 

            -- Add preceeding dataset record (with truncated duration/interval)
            -- at beginning of results
            --
            INSERT INTO @TX( Seq,
                             Dataset,
                             ID,
                             [Day],
                             Time_Start,
                             Time_End,
                             Duration,
                             [Interval],
                             Instrument )
            Values (@firstRunSeq - 1, 
                    @precDataset, 
                    @precID, 
                    1,                -- Day of month
                    @precStart, 
                    @precEnd, 
                    @precDuration,
                    @precInterval, 
                    @instrumentIDFirst)
        END

        ---------------------------------------------------
        -- Need to truncate part of last run or following
        -- interval that hangs over end of month
        ---------------------------------------------------
        
        -- If end of last run hangs over start of succeeding month,
        -- truncate duration and set interval to zero.

        -- Otherwise, if interval hangs over succeeding month, truncate it
        --
        Declare @lastRunStart datetime 
        Declare @lastRunEnd datetime 
        Declare @lastRunInterval int

        SELECT @lastRunStart = Time_Start,
               @lastRunEnd = Time_End,
               @lastRunInterval = [Interval]
        FROM @TX
        WHERE Seq = @lastRunSeq
        
        IF @lastRunEnd > @firstDayOfTrailingMonth
        BEGIN 
            UPDATE @TX
            SET [Interval] = 0,
                Duration = DATEDIFF(MINUTE, @lastRunStart, @firstDayOfTrailingMonth)
            WHERE Seq = @lastRunSeq
        END 
        ELSE IF DATEADD(MINUTE, @lastRunInterval, @lastRunEnd) > @firstDayOfTrailingMonth
        BEGIN
            UPDATE @TX
            SET [Interval] = DATEDIFF(MINUTE, @lastRunEnd, @firstDayOfTrailingMonth)
            WHERE Seq = @lastRunSeq
        END

        ---------------------------------------------------
        -- Fill in interval comment information
        ---------------------------------------------------

        UPDATE @TX
        SET [Comment] = CONVERT(varchar(256), TRI.[Comment]),
            CommentState = CASE
                               WHEN TRI.Instrument IS NULL THEN 'x'
                               ELSE (CASE
                                         WHEN ISNULL(TRI.[Comment], '') = '' THEN '-'
                                         ELSE '+'
                                     END)
                           END
        FROM @TX T
             LEFT OUTER JOIN T_Run_Interval TRI
               ON T.ID = TRI.ID

        RETURN
    END

GO
