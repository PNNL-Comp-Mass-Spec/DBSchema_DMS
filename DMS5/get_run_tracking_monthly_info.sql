/****** Object:  UserDefinedFunction [dbo].[get_run_tracking_monthly_info] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[get_run_tracking_monthly_info]
/****************************************************
**
**  Desc:   Returns run tracking information for given instrument
**
**  Auth:   grk
**          02/14/2012 grk - initial release
**          02/15/2012 grk - added interval comment handing
**          06/08/2012 grk - added lookup for @maxNormalInterval
**          04/27/2020 mem - Update data validation checks
**                         - Make several columns in the output table nullable
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @instrument VARCHAR(64), -- 'VOrbiETD04'
    @year VARCHAR(8), -- '2012'
    @month VARCHAR(12), -- '1'
    @options VARCHAR(32) = ''
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
        Declare @maxNormalInterval INT = dbo.get_long_interval_threshold()
        Declare @message VARCHAR(512) = ''

        ---------------------------------------------------
        -- check arguments
        ---------------------------------------------------

        IF ISNULL(@year, 0) = 0 OR ISNULL(@month, 0) = 0 OR ISNULL(@instrument, '') = ''
        BEGIN
            INSERT INTO @TX (Seq, Dataset) VALUES (1, 'Bad arguments')
            RETURN
        END

        ---------------------------------------------------
        -- get instrument ID
        ---------------------------------------------------

        Declare @instrumentID INT
        SELECT @instrumentID = Instrument_ID FROM T_Instrument_Name WHERE IN_name = @instrument
        IF ISNULL(@instrumentID, 0) = 0
        BEGIN
            INSERT INTO @TX (Seq, Dataset) VALUES (1, 'Unrecognized instrument')
            RETURN
        END

        ---------------------------------------------------
        -- set up dates for beginning and end of month
        ---------------------------------------------------

        Declare @startDate VARCHAR(16) = @month + '/1/' + @year
        Declare @firstDayOfStartingMonth DATETIME = CONVERT(DATETIME, @startDate, 102);
        Declare @firstDayOfTrailingMonth DATETIME = DATEADD(MONTH, 1, @firstDayOfStartingMonth)

        ---------------------------------------------------
        -- get datasets whose start time falls within month
        ---------------------------------------------------
        Declare @seqIncrement INT = 1
        Declare @seqOffset INT = 0

        INSERT  INTO @TX
        (
            Seq,
            ID ,
            Dataset ,
            [Day],
            Time_Start ,
            Time_End ,
            Duration,
            Interval,
            Instrument
        )
        SELECT
            (@seqIncrement * ((ROW_NUMBER() OVER(ORDER BY TD.Acq_Time_Start ASC)) -1) + 1) + @seqOffset AS 'Seq',
            TD.Dataset_ID AS ID ,
            TD.Dataset_Num AS Dataset ,
            DATEPART(DAY, TD.Acq_Time_Start) AS [Day],
            TD.Acq_Time_Start AS Time_Start ,
            TD.Acq_Time_End AS Time_End,
            TD.Acq_Length_Minutes AS Duration ,
            TD.Interval_to_Next_DS AS Interval ,
            @instrument AS Instrument
        FROM
            T_Dataset AS TD
        WHERE
            TD.DS_instrument_name_ID = @instrumentID
            AND @firstDayOfStartingMonth <= TD.Acq_Time_Start
            AND TD.Acq_Time_Start < @firstDayOfTrailingMonth
        ORDER BY TD.Acq_Time_Start

        ---------------------------------------------------
        -- need to add some part of run or interval from
        -- preceding month if first run in month is not
        -- close to beginning of month
        ---------------------------------------------------

        Declare @firstRunSeq int
        Declare @lastRunSeq int
        SELECT @firstRunSeq = MIN(Seq), @lastRunSeq = MAX(Seq) FROM @TX

        Declare @firstStart DATETIME
        SELECT @firstStart = Time_Start FROM @TX WHERE Seq = @firstRunSeq

        Declare @initialGap INT = DATEDIFF(MINUTE, @firstDayOfStartingMonth, @firstStart)

        -- get preceeding dataset (latest with starting time preceding this month)
        --
        IF DATEDIFF(MINUTE, @firstDayOfStartingMonth, @firstStart) > @maxNormalInterval
        BEGIN
            Declare @precID INT
            Declare @precDataset VARCHAR(128)
            Declare @precStart DATETIME
            Declare @precEnd DATETIME
            Declare @precDuration INT
            Declare @precInterval INT

            SELECT TOP 1
                @precID = TD.Dataset_ID ,
                @precDataset = TD.Dataset_Num,
                @precStart = TD.Acq_Time_Start ,
                @precEnd = TD.Acq_Time_End,
                @precDuration = TD.Acq_Length_Minutes,
                @precInterval = TD.Interval_to_Next_DS
            FROM
                T_Dataset AS TD
            WHERE
                TD.DS_instrument_name_ID = @instrumentID
                AND TD.Acq_Time_Start < @firstDayOfStartingMonth
                AND TD.Acq_Time_Start > DATEADD(DAY, -90, @firstDayOfStartingMonth)
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

            -- add preceeding dataset record (with truncated duration/interval)
            -- at beginning of results
            --
            INSERT INTO @TX (Seq, Dataset, ID, [Day], Time_Start, Time_End, Duration, Interval, Instrument)
            VALUES (@firstRunSeq - 1, @precDataset, @precID, 1, @precStart, @precEnd, @precDuration, @precInterval, @instrument)
        END

        ---------------------------------------------------
        -- need to truncate part of last run or following
        -- interval that hangs over end of month
        ---------------------------------------------------

        -- if end of last run hangs over start of succeeding month
        -- truncate duration and set interval to zero
        -- otherwise, if interval hangs over succeeding month,
        -- truncate it
        --
        Declare @lastRunStart DATETIME
        Declare @lastRunEnd DATETIME
        Declare @lastRunInterval INT
        SELECT
            @lastRunStart = Time_Start,
            @lastRunEnd = Time_End ,
            @lastRunInterval = [Interval]
        FROM @TX
        WHERE Seq = @lastRunSeq

        IF @lastRunEnd > @firstDayOfTrailingMonth
        BEGIN
            UPDATE @TX
            SET
            [Interval] = 0,
            Duration = DATEDIFF(MINUTE, @lastRunStart, @firstDayOfTrailingMonth)
            WHERE Seq = @lastRunSeq
        END
        ELSE IF DATEADD(MINUTE, @lastRunInterval, @lastRunEnd) > @firstDayOfTrailingMonth
        BEGIN
            UPDATE @TX
            SET
            [Interval] = DATEDIFF(MINUTE, @lastRunEnd, @firstDayOfTrailingMonth)
            WHERE Seq = @lastRunSeq
        END

        ---------------------------------------------------
        -- fill in interval comment information
        ---------------------------------------------------

        UPDATE @TX
        SET Comment = CONVERT(VARCHAR(256), TRI.Comment),
            CommentState = CASE WHEN TRI.Instrument IS NULL THEN 'x'
             ELSE ( CASE WHEN ISNULL(TRI.Comment, '') = '' THEN '-'
                         ELSE '+'
                    END ) END
        FROM @TX T
        LEFT OUTER JOIN T_Run_Interval TRI ON T.ID = TRI.ID

        RETURN
    END

GO
GRANT VIEW DEFINITION ON [dbo].[get_run_tracking_monthly_info] TO [DDL_Viewer] AS [dbo]
GO
