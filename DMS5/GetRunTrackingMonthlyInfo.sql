/****** Object:  UserDefinedFunction [dbo].[GetRunTrackingMonthlyInfo] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION dbo. GetRunTrackingMonthlyInfo
/****************************************************
**
**	Desc: 
**  Returns run tracking information for given instrument
**
**	Return values: 
**
**	Parameters:
**	
**	Auth: grk   
**		02/14/2012 grk - initial release
**		02/15/2012 grk - added interval comment handing
**		06/08/2012 grk - added lookup for @maxNormalInterval
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
	ID INT ,
	Dataset VARCHAR(128) ,
	[Day] INT,
	Duration int NULL,
	Interval INT NULL,
	Time_Start DATETIME ,
	Time_End DATETIME ,
	Instrument VARCHAR(128) ,
	CommentState VARCHAR(24),
	Comment VARCHAR(256)
)
AS
	BEGIN
		DECLARE @maxNormalInterval INT = dbo.GetLongIntervalThreshold()
		DECLARE @message VARCHAR(512) = ''
	
		---------------------------------------------------
		-- check arguments
		---------------------------------------------------

		IF ISNULL(@year, 0) = 0 OR ISNULL(@month, 0) = 0 OR ISNULL(@instrument, '') = ''
		BEGIN
			INSERT INTO @TX (Dataset) VALUES ('Bad arguments')
			RETURN 
		END

		---------------------------------------------------
		-- get instrument ID
		---------------------------------------------------
		
		DECLARE @instrumentID INT
		SELECT @instrumentID = Instrument_ID FROM T_Instrument_Name WHERE IN_name = @instrument
		IF ISNULL(@instrumentID, 0) = 0
		BEGIN
			INSERT INTO @TX (Dataset) VALUES ('Unrecognized instrument')
			RETURN 
		END

		---------------------------------------------------
		-- set up dates for beginning and end of month 
		---------------------------------------------------
		
		DECLARE @startDate VARCHAR(16) = @month + '/1/' + @year
		DECLARE @firstDayOfStartingMonth DATETIME = CONVERT(DATETIME, @startDate, 102);
		DECLARE @firstDayOfTrailingMonth DATETIME = DATEADD(MONTH, 1, @firstDayOfStartingMonth)

		---------------------------------------------------
		-- get datasets whose start time falls within month 
		---------------------------------------------------
		DECLARE @seqIncrement INT = 1
		DECLARE @seqOffset INT = 0

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

		DECLARE @firstRunSeq int
		DECLARE @lastRunSeq int
		SELECT @firstRunSeq = MIN(Seq), @lastRunSeq = MAX(Seq) FROM @TX
		
		DECLARE @firstStart DATETIME
		SELECT @firstStart = Time_Start FROM @TX WHERE Seq = @firstRunSeq
		
		DECLARE @initialGap INT = DATEDIFF(MINUTE, @firstDayOfStartingMonth, @firstStart)
		
		-- get preceeding dataset (latest with starting time preceding this month)
		--
		IF DATEDIFF(MINUTE, @firstDayOfStartingMonth, @firstStart) > @maxNormalInterval
		BEGIN 
			DECLARE @precID INT
			DECLARE @precDataset VARCHAR(128) 
			DECLARE @precStart DATETIME
			DECLARE @precEnd DATETIME 
			DECLARE @precDuration INT
			DECLARE @precInterval INT 

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
				SET @precDuration = 0
				SET @precInterval = @initialGap
			END
			ELSE
			BEGIN 
				SET @precDuration = DATEDIFF(MINUTE, @firstDayOfStartingMonth, @precStart)
			END 

			-- add preceeding dataset record (with truncated duration/interval)
			-- at beginning of results
			--
			INSERT INTO @TX 
			(Seq, Dataset, ID, [Day], Time_Start, Time_End, Duration, Interval, Instrument) 
			VALUES 
			(@firstRunSeq - 1, @precDataset, @precID, 1, @precStart, @precEnd, @precDuration, @precInterval, @instrument)
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
		DECLARE @lastRunStart DATETIME 
		DECLARE @lastRunEnd DATETIME 
		DECLARE @lastRunInterval INT
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
