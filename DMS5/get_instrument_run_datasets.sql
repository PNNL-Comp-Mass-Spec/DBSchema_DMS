/****** Object:  UserDefinedFunction [dbo].[GetInstrumentRunDatasets] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[GetInstrumentRunDatasets]
/****************************************************
**
**  Desc:
**  Returns list of datasets and acquisition time information for given instrument
**
**  Return values:
**
**  Parameters:
**
**
**  Auth:   grk
**  Date:   09/14/2010
**          09/04/2010 grk - initial release
**          02/15/2012 mem - Now using T_Dataset.Acq_Length_Minutes
**
*****************************************************/
(
    @mostRecentWeeks INT = 4,
    @instrument VARCHAR(64) = 'VOrbiETD04'
)
RETURNS @TX TABLE (
    Seq INT primary key,
    ID INT ,
    Dataset VARCHAR(128) ,
    State VARCHAR(32) ,
    Rating VARCHAR(32) ,
    Duration int NULL,
    Time_Start DATETIME ,
    Time_End DATETIME ,
    Request INT ,
    EUS_Proposal VARCHAR(32) ,
    EUS_Usage VARCHAR(64),
    Work_Package VARCHAR(32),
    LC_Column VARCHAR(128) ,
    Instrument VARCHAR(128)
)
AS
    BEGIN
        ---------------------------------------------------
        --
        ---------------------------------------------------

        IF ISNULL(@mostRecentWeeks, 0) = 0 OR ISNULL(@instrument, '') = ''
        BEGIN
            INSERT INTO @TX (Dataset) VALUES ('Bad arguments')
            RETURN
        END

        ---------------------------------------------------
        -- get datasets for instrument within time window
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
            Instrument
        )
        SELECT
            2 * ((ROW_NUMBER() OVER(ORDER BY T_Dataset.Acq_Time_Start ASC)) -1) + 1 AS 'Seq',
            T_Dataset.Dataset_ID AS ID ,
            T_Dataset.Dataset_Num AS Dataset ,
            T_Dataset.Acq_Time_Start AS Time_Start,
            T_Dataset.Acq_Time_End AS Time_End,
            T_Dataset.Acq_Length_Minutes AS Duration,
            @instrument
        FROM
            T_Dataset
            INNER JOIN T_Instrument_Name ON T_Dataset.DS_instrument_name_ID = T_Instrument_Name.Instrument_ID
        WHERE
            ( T_Dataset.Acq_Time_Start > DATEADD(Week, -1 * @mostRecentWeeks, GETDATE()) )
        AND ( T_Instrument_Name.IN_name = @instrument )

        ---------------------------------------------------
        -- create inter-run interval rows between dataset rows
        ---------------------------------------------------

        DECLARE @maxSeq INT
        SELECT @maxSeq = MAX(Seq) FROM @TX

        DECLARE @start DATETIME, @end DATETIME, @interval INT
        DECLARE @index INT = 1
        WHILE @index < @maxSeq
        BEGIN
            SELECT @start = Time_Start FROM @TX WHERE Seq = @index + 2
            SELECT @end = Time_End FROM @TX WHERE Seq = @index
            SET  @interval = CASE WHEN @start <= @end THEN 0 ELSE ISNULL(DATEDIFF(minute, @end, @start), 0) END

            INSERT INTO @TX ( Seq , ID , Dataset , Time_Start, Time_End, Duration, Instrument )
            VALUES (@index + 1 , 0 , 'Interval' , @end, @start, @interval, @instrument )


            SET @index = @index + 2
        END

        ---------------------------------------------------
        -- overall time stats
        ---------------------------------------------------

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
        SELECT @normalIntervalMinutes = SUM (ISNULL(Duration, 0)) FROM @TX WHERE ID = 0 AND Duration < 10
        SELECT @longIntervalMinutes = SUM (ISNULL(Duration, 0)) FROM @TX WHERE ID = 0 AND Duration >= 10

        DECLARE @s VARCHAR(256) = ''
        SET @s = @s + 'total:' + CONVERT(VARCHAR(12), @totalMinutes)
        SET @s = @s +  ', normal acquisition:' + CONVERT(VARCHAR(12), ISNULL(@acquisitionMinutes, 0) + ISNULL(@normalIntervalMinutes, 0))
        SET @s = @s + ', long intervals:' + CONVERT(VARCHAR(12), @longIntervalMinutes)

        INSERT INTO @TX (Seq, Dataset) VALUES (0, @s)

        ---------------------------------------------------
        -- fill in more information about datasets
        ---------------------------------------------------

        UPDATE @TX
        SET
            State = T_DatasetStateName.DSS_name,
            Rating = T_DatasetRatingName.DRN_name ,
            LC_Column = 'C:' + T_LC_Column.SC_Column_Number ,
            Request = T_Requested_Run.ID ,
            Work_Package = T_Requested_Run.RDS_WorkPackage  ,
            EUS_Proposal = T_Requested_Run.RDS_EUS_Proposal_ID  ,
            EUS_Usage = T_EUS_UsageType.Name
        FROM @TX T
        INNER JOIN T_Dataset ON T.ID = dbo.T_Dataset.Dataset_ID
        INNER JOIN T_DatasetStateName ON T_Dataset.DS_state_ID = T_DatasetStateName.Dataset_state_ID
        INNER JOIN T_DatasetRatingName ON T_Dataset.DS_rating = T_DatasetRatingName.DRN_state_ID
        INNER JOIN T_LC_Column ON T_Dataset.DS_LC_column_ID = T_LC_Column.ID
        LEFT OUTER JOIN T_Requested_Run ON T_Dataset.Dataset_ID = T_Requested_Run.DatasetID
        INNER JOIN T_EUS_UsageType ON dbo.T_Requested_Run.RDS_EUS_UsageType = dbo.T_EUS_UsageType.ID

    RETURN
    END

GO
GRANT VIEW DEFINITION ON [dbo].[GetInstrumentRunDatasets] TO [DDL_Viewer] AS [dbo]
GO
