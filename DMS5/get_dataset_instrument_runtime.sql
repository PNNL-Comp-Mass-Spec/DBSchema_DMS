/****** Object:  UserDefinedFunction [dbo].[get_dataset_instrument_runtime] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[get_dataset_instrument_runtime]
/****************************************************
**
**  Desc:
**      Returns list of datasets and acquisition time information for given instrument
**
**  Auth:   grk
**  Date:   05/26/2011 grk - initial release
**          12/02/2011 mem - Added several Campaign-related columns: Campaign_ID, Fraction_EMSL_Funded, and Campaign_Proposals
**          01/31/2012 grk - Added Interval column to output and made separate interval rows an option
**          02/06/2012 grk - Added @endIntervalEOD padding to pick up trailing interval
**          02/07/2012 grk - Added anchoring of long intervals to beginning and end of month.
**          02/15/2012 mem - Now using T_Dataset.Acq_Length_Minutes
**          06/08/2012 grk - added lookup for @maxNormalInterval
**          04/05/2017 mem - Compute Fraction_EMSL_Funded using EUS usage type (previously computed using CM_Fraction_EMSL_Funded, which is estimated by the user for each campaign)
**          05/16/2022 mem - Add renamed proposal type 'Resource Owner'
**          05/18/2022 mem - Treat additional proposal types as not EMSL funded
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          03/02/2023 mem - Use renamed table names
**          03/20/2023 mem - Treat proposal types 'Capacity' and 'Staff Time' as EMSL funded
**
*****************************************************/
(
    @startInterval datetime,
    @endInterval datetime,
    @instrument VARCHAR(64) = 'VOrbiETD04',
    @options VARCHAR(32) = 'Show All'
)
RETURNS @TX TABLE (
    Seq INT primary key,
    ID INT ,
    Dataset VARCHAR(128) ,
    State VARCHAR(32) ,
    Rating VARCHAR(32) ,
    Duration int NULL,
    Interval INT NULL,
    Time_Start DATETIME ,
    Time_End DATETIME ,
    Request INT ,
    EUS_Proposal VARCHAR(32) ,
    EUS_Usage VARCHAR(64),
    EUS_Proposal_Type VARCHAR(100),
    Work_Package VARCHAR(32),
    LC_Column VARCHAR(128) ,
    Instrument VARCHAR(128),
    Campaign_ID int,
    Fraction_EMSL_Funded decimal(3, 2),
    Campaign_Proposals varchar(256)
)
AS
    BEGIN
        DECLARE @maxNormalInterval INT = dbo.get_long_interval_threshold()

        ---------------------------------------------------
        -- Set up flags that control content
        -- according to selected options
        ---------------------------------------------------

        DECLARE @includeAcquisitions TINYINT = 1
        DECLARE @includeIncrements TINYINT = 1
        DECLARE @includeStats TINYINT = 1
        DECLARE @seqIncrement INT = 2
        DECLARE @seqOffset INT = 0
        DECLARE @longIntervalsOnly TINYINT = 0
        DECLARE @anchorIntervalsToMonth TINYINT = 0
        --
        SET @anchorIntervalsToMonth    = 1
        --
        IF @options = 'Show All'
        BEGIN
            SET @includeAcquisitions = 1
            SET @includeIncrements = 1
            SET @includeStats = 1
            SET @longIntervalsOnly = 0
            SET @seqIncrement = 2
        END
        --
        IF @options = 'No Intervals'
        BEGIN
            SET @includeAcquisitions = 1
            SET @includeIncrements = 0
            SET @includeStats = 0
            SET @longIntervalsOnly = 0
            SET @seqIncrement = 2
        END
        --
        IF @options = 'Intervals Only'
        BEGIN
            SET @includeAcquisitions = 0
            SET @includeIncrements = 1
            SET @includeStats = 0
            SET @longIntervalsOnly = 0
            SET @seqIncrement = 2
        END
        --
        IF @options = 'Long Intervals'
        BEGIN
            SET @includeAcquisitions = 0
            SET @includeIncrements = 1
            SET @includeStats = 0
            SET @longIntervalsOnly = 1
            SET @seqIncrement = 2
        END

        ---------------------------------------------------
        -- Set up dates for beginning and end of month anchors
        -- (anchor is fake dataset with zero duration)
        ---------------------------------------------------

        DECLARE @firstDayOfStartingMonth DATETIME = DATEADD(MONTH, DATEDIFF(MONTH, 0, @startInterval), 0)
        DECLARE @firstDayOfTrailingMonth DATETIME = DATEADD(MONTH, DATEDIFF(MONTH, 0, @endInterval) + 1, 0)

        ---------------------------------------------------
        -- Check arguments
        ---------------------------------------------------

        IF ISNULL(@startInterval, 0) = 0 OR ISNULL(@endInterval, 0) = 0 OR Coalesce(@instrument, '') = ''
        Begin
            INSERT  INTO @TX
            (
                Seq,
                ID ,
                Dataset ,
                Time_Start ,
                Time_End ,
                Duration,
                Instrument,
                Interval
            ) VALUES (
                1, 0, 'Bad arguments: specify start and end date, plus instrument name', GetDate(), GetDate(), 0, '', 0
            )
            RETURN
        END

        ---------------------------------------------------
        -- Update @endIntervalEOD to span thru 23:59:59.997
        -- on the end day
        ---------------------------------------------------

        DECLARE @endIntervalEOD DATETIME = Convert(datetime, Floor(Convert(float, @endInterval)))
        set @endIntervalEOD = DateAdd(second, 86399, @endIntervalEOD)
        set @endIntervalEOD = DateAdd(millisecond, 995, @endIntervalEOD)

        ---------------------------------------------------
        -- Optionally set up anchor for start of month
        ---------------------------------------------------

        IF @anchorIntervalsToMonth = 1
        BEGIN
            SET @seqOffset = 2
            INSERT  INTO @TX
            (
                Seq,
                ID ,
                Dataset ,
                Time_Start ,
                Time_End ,
                Duration,
                Instrument,
                Interval
            ) VALUES (
                1, 0, 'Anchor', @firstDayOfStartingMonth, @firstDayOfStartingMonth, 0, @instrument, 0
            )
        END
        ELSE
        BEGIN
            SET @endIntervalEOD = DATEADD(DAY, 1, @endInterval)
        END

        ---------------------------------------------------
        -- Get datasets for instrument within time window
        -- in order based on acquisition start time
        ---------------------------------------------------

        INSERT  INTO @TX
        (
            Seq,
            ID ,
            Dataset ,
            Time_Start ,
            Time_End ,
            Duration,
            Instrument,
            Interval
        )
        SELECT
            (@seqIncrement * ((ROW_NUMBER() OVER(ORDER BY T_Dataset.Acq_Time_Start ASC)) -1) + 1) + @seqOffset AS 'Seq',
            T_Dataset.Dataset_ID AS ID ,
            T_Dataset.Dataset_Num AS Dataset ,
            T_Dataset.Acq_Time_Start AS Time_Start,
            T_Dataset.Acq_Time_End AS Time_End,
            T_Dataset.Acq_Length_Minutes AS Duration,
            @instrument,
            0
        FROM
            T_Dataset
            INNER JOIN T_Instrument_Name ON T_Dataset.DS_instrument_name_ID = T_Instrument_Name.Instrument_ID
        WHERE
            @startInterval <= T_Dataset.Acq_Time_Start AND T_Dataset.Acq_Time_Start <= @endIntervalEOD AND
            T_Instrument_Name.IN_name = @instrument


        ---------------------------------------------------
        -- Optionally set up anchor for end of month
        ---------------------------------------------------

        DECLARE @endSeq INT
        SELECT @endSeq = MAX(Seq) + 2 FROM @TX
        --
        IF @anchorIntervalsToMonth = 1
        BEGIN
            INSERT  INTO @TX
            (
                Seq,
                ID ,
                Dataset ,
                Time_Start ,
                Time_End ,
                Duration,
                Instrument,
                Interval
            ) VALUES (
                @endSeq, 0, 'Anchor', @firstDayOfTrailingMonth, @firstDayOfTrailingMonth, 0, @instrument, 0
            )
        END

        ---------------------------------------------------
        -- Calculate inter-run intervals and update dataset rows
        -- and (optionally) insert interval rows between dataset rows
        ---------------------------------------------------

        DECLARE @maxSeq INT
        SELECT @maxSeq = MAX(Seq) FROM @TX

        DECLARE @start DATETIME, @end DATETIME, @interval INT
        DECLARE @index INT = 1
        WHILE @index < @maxSeq
        BEGIN
            SELECT @start = Time_Start FROM @TX WHERE Seq = @index + @seqIncrement
            SELECT @end = Time_End FROM @TX WHERE Seq = @index
            SET  @interval = CASE WHEN @start <= @end THEN 0 ELSE ISNULL(DATEDIFF(minute, @end, @start), 0) END

            UPDATE @TX SET Interval = ISNULL(@interval, 0) WHERE Seq = @index

            INSERT INTO @TX ( Seq , ID , Dataset , Time_Start, Time_End, Duration, Instrument )
            VALUES (@index + 1 , 0 , 'Interval' , @end, @start, ISNULL(@interval, 0), @instrument )

            SET @index = @index + @seqIncrement
        END

        ---------------------------------------------------
        -- Remove extraneous entries caused by padded end date
        ---------------------------------------------------

        DELETE FROM @TX WHERE Time_Start >= @endIntervalEOD
/*
        ---------------------------------------------------
        -- Overall time stats
        ---------------------------------------------------
        IF @includeStats = 1
        BEGIN
            DECLARE @earliestStart DATETIME ,
            @latestFinish DATETIME ,
            @totalMinutes INT ,
            @acquisitionMinutes INT ,
            @normalIntervalMinutes INT ,
            @longIntervalMinutes INT

            SELECT @earliestStart = MIN(Time_Start) FROM @TX
            SELECT @latestFinish = MAX(Time_End) FROM @TX

            SET @totalMinutes = DATEDIFF(minute, @earliestStart, @latestFinish)

            SELECT @acquisitionMinutes = SUM(ISNULL(Duration, 0)) FROM @TX WHERE ID <> 0
            SELECT @normalIntervalMinutes = SUM (ISNULL(Duration, 0)) FROM @TX WHERE ID = 0 AND Duration < @maxNormalInterval
            SELECT @longIntervalMinutes = SUM (ISNULL(Duration, 0)) FROM @TX WHERE ID = 0 AND Duration >= @maxNormalInterval

            DECLARE @s VARCHAR(256) = ''
            SET @s = @s + 'total:' + CONVERT(VARCHAR(12), @totalMinutes)
            SET @s = @s +  ', normal acquisition:' + CONVERT(VARCHAR(12), ISNULL(@acquisitionMinutes, 0) + ISNULL(@normalIntervalMinutes, 0))
            SET @s = @s + ', long intervals:' + CONVERT(VARCHAR(12), @longIntervalMinutes)

            INSERT INTO @TX (Seq, Dataset) VALUES (0, @s)
        END
*/
        IF @includeAcquisitions = 1
        BEGIN
            ---------------------------------------------------
            -- Fill in more information about datasets
            -- if acquisition rows are included in output
            ---------------------------------------------------

            UPDATE @TX
            SET
                State = DSN.DSS_name,
                Rating = DRN.DRN_name ,
                LC_Column = 'C:' + LC.SC_Column_Number ,
                Request = RR.ID ,
                Work_Package = RR.RDS_WorkPackage  ,
                EUS_Proposal = RR.RDS_EUS_Proposal_ID  ,
                EUS_Usage = EUT.Name,
                EUS_Proposal_Type = EUP.Proposal_Type,
                Campaign_ID  = C.Campaign_ID,
                -- Fraction_EMSL_Funded = C.CM_Fraction_EMSL_Funded,   -- Campaign based estimation of fraction EMSL funded; this has been replaced by the following case statement
                Fraction_EMSL_Funded =
                   CASE
                   WHEN Coalesce(EUP.Proposal_Type, 'PROPRIETARY')
                        IN ('Partner', 'Proprietary', 'Proprietary Public', 'Proprietary_Public', 'Resource Owner') THEN 0  -- Not EMSL Funded
                   ELSE 1             -- EMSL Funded:
                                      -- 'Exploratory Research', 'FICUS JGI-EMSL', 'FICUS Research', 'Intramural S&T',
                                      -- 'Large-Scale EMSL Research', 'Limited Scope', 'Science Area Research',
                                      -- 'Capacity', 'Staff Time'
                   END,
                Campaign_Proposals = C.CM_EUS_Proposal_List
            FROM @TX T INNER JOIN
                T_Dataset DS ON T.ID = DS.Dataset_ID INNER JOIN
                T_Experiments E ON DS.Exp_ID = E.Exp_ID INNER JOIN
                T_Campaign C ON E.EX_campaign_ID = C.Campaign_ID INNER JOIN
                T_Dataset_State_Name DSN ON DS.DS_state_ID = DSN.Dataset_state_ID INNER JOIN
                T_Dataset_Rating_Name DRN ON DS.DS_rating = DRN.DRN_state_ID INNER JOIN
                T_LC_Column LC ON DS.DS_LC_column_ID = LC.ID LEFT OUTER JOIN
                T_Requested_Run RR ON DS.Dataset_ID = RR.DatasetID LEFT OUTER JOIN
                T_EUS_UsageType EUT ON RR.RDS_EUS_UsageType = EUT.ID LEFT OUTER JOIN
                T_EUS_Proposals EUP ON RR.RDS_EUS_Proposal_ID = EUP.Proposal_ID

        END

        ---------------------------------------------------
        -- Optionally remove acquistion rows
        ---------------------------------------------------
        IF @includeAcquisitions = 0
        BEGIN
            DELETE FROM @TX WHERE NOT Dataset = 'Interval'
        END

        ---------------------------------------------------
        -- Optionally remove all intervals
        ---------------------------------------------------
        IF @includeIncrements = 0
        BEGIN
            DELETE FROM @TX WHERE Dataset = 'Interval'
        END

        ---------------------------------------------------
        -- Optionally remove normal intervals
        ---------------------------------------------------
        IF @longIntervalsOnly = 1
        BEGIN
            DELETE FROM @TX WHERE Dataset = 'Interval' AND Duration <= @maxNormalInterval
        END

    RETURN
    END

GO
GRANT VIEW DEFINITION ON [dbo].[get_dataset_instrument_runtime] TO [DDL_Viewer] AS [dbo]
GO
