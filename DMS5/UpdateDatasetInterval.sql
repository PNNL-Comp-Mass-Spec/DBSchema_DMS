/****** Object:  StoredProcedure [dbo].[UpdateDatasetInterval] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE dbo.UpdateDatasetInterval
/****************************************************
**
**  Desc: 
**    Updates dataset interval and creates entries 
**    for long intervals in the intervals table 
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**  Auth:	grk
**  Date:	02/08/2012 
**			02/10/2012 mem - Now updating Acq_Length_Minutes in T_Dataset
**			02/13/2012 grk - Raised @maxNormalInterval to ninety minutes
**			02/15/2012 mem - No longer updating Acq_Length_Minutes in T_Dataset since now a computed column
**			03/07/2012 mem - Added parameter @infoOnly
**			               - Now validating @instrumentName
**			03/29/2012 grk - interval values in T_Run_Interval were not being updated
**			04/10/2012 grk - now deleting "short" long intervals
**			06/08/2012 grk - added lookup for @maxNormalInterval
**			08/30/2012 grk - extended dataset update to include beginning of next month
**			11/19/2013 mem - Now updating Interval_to_Next_DS in T_Dataset only if the newly computed interval differs from the stored interval
**			02/23/2016 mem - Add set XACT_ABORT on
**    
*****************************************************/
(
	@instrumentName VARCHAR(64),
	@startDate DATETIME,
	@endDate DATETIME,
	@message varchar(512) = '' output,
	@infoOnly tinyint = 0
)
AS
	Set XACT_ABORT, nocount on

	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0

	set @message = ''
	Set @infoOnly = IsNull(@infoOnly, 0)
	
	DECLARE @maxNormalInterval INT = dbo.GetLongIntervalThreshold()
	
	BEGIN TRY 

		---------------------------------------------------
		-- Make sure @instrumentName is valid (and is properly capitalized)
		---------------------------------------------------
		Declare @instrumentNameMatch varchar(128) = ''
		
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
			Set @instrumentName = @instrumentNameMatch
		
		---------------------------------------------------
		-- temp table to hold time information about datasets
		---------------------------------------------------
		--
		CREATE TABLE #Tmp_Durations (
			Seq INT primary KEY IDENTITY(1,1) NOT NULL,
			ID INT ,					-- DatasetID
			Dataset VARCHAR(128) ,
			Instrument VARCHAR(128),
			Time_Start DATETIME ,
			Time_End DATETIME,
			Duration int,				-- Duration of run, in minutes
			Interval INT NULL
		)

		INSERT INTO #Tmp_Durations (
			ID ,			-- DatasetID
			Dataset ,
			Instrument,
			Time_Start ,
			Time_End ,
			Duration
		)
		SELECT  DS.Dataset_ID ,
				DS.Dataset_Num,
				TIN.IN_name,
				DS.Acq_Time_Start,
				DS.Acq_Time_End,
				DATEDIFF(minute, DS.Acq_Time_Start, DS.Acq_Time_End)
		FROM    T_Dataset DS
				INNER JOIN T_Instrument_Name TIN ON DS.DS_instrument_name_ID = TIN.Instrument_ID
		WHERE	@startDate <= DS.Acq_Time_Start AND DS.Acq_Time_Start <= @endDate
				AND TIN.IN_name = @instrumentName
		ORDER BY DS.Acq_Time_Start

		---------------------------------------------------
		-- calculate inter-run intervals and update temp table
		---------------------------------------------------

		DECLARE @maxSeq INT
		SELECT @maxSeq = MAX(Seq) FROM #Tmp_Durations

		DECLARE @start DATETIME, @end DATETIME, @interval INT 
		DECLARE @index INT = 1
		DECLARE @seqIncrement INT = 1
		WHILE @index < @maxSeq
		BEGIN
			SET @start = NULL
			SET @end = NULL 
			SELECT @start = Time_Start FROM #Tmp_Durations WHERE Seq = @index + @seqIncrement
			SELECT @end = Time_End FROM #Tmp_Durations WHERE Seq = @index
			SET  @interval = CASE WHEN @start <= @end THEN 0 ELSE ISNULL(DATEDIFF(minute, @end, @start), 0) END 
			
			-- make sure that start and end times are not null
			--
			IF (NOT @start IS NULL) AND (NOT @end IS NULL)
			BEGIN 
				UPDATE #Tmp_Durations SET Interval = ISNULL(@interval, 0) WHERE Seq = @index
			END 

			SET @index = @index + @seqIncrement
		END

		---------------------------------------------------
		-- transaction
		---------------------------------------------------
		
		declare @transName varchar(32)
		set @transName = 'UpdateDatasetInterval'

		---------------------------------------------------
		-- update dataset table
		---------------------------------------------------

		If @infoOnly > 0
		Begin
			SELECT @instrumentName AS Instrument,
			       DS.Dataset_Num as Dataset,
			       DS.Dataset_ID,
			       DS.DS_Created,
			       DS.Acq_Time_Start,
			       #Tmp_Durations.[Interval] AS Interval_to_Next_DS,
			       CASE When [Interval] > @maxNormalInterval Then 'Yes' Else '' End As Long_Interval
			FROM T_Dataset DS
			     INNER JOIN #Tmp_Durations
			       ON DS.Dataset_ID = #Tmp_Durations.ID
			ORDER BY CASE When [Interval] > @maxNormalInterval Then 0 Else 1 End, DS.Dataset_ID

		End
		Else
		Begin
		
			BEGIN TRANSACTION @transName

			---------------------------------------------------
			-- update interval for dataset table
			---------------------------------------------------
			
			UPDATE DS
			SET Interval_to_Next_DS = #Tmp_Durations.[Interval]
			FROM T_Dataset DS
			     INNER JOIN #Tmp_Durations
			       ON DS.Dataset_ID = #Tmp_Durations.ID
			WHERE IsNull(DS.Interval_to_Next_DS, 0) <> Coalesce(#Tmp_Durations.[Interval], DS.Interval_to_Next_DS, 0)

			---------------------------------------------------
			-- update interval in long interval table
			---------------------------------------------------

			UPDATE dbo.T_Run_Interval
			SET [Interval] = #Tmp_Durations.[Interval]
			FROM dbo.T_Run_Interval target
			     INNER JOIN #Tmp_Durations
			       ON target.ID = #TMP_Durations.ID
			WHERE IsNull(target.[Interval], 0) <> Coalesce(#Tmp_Durations.[Interval], target.[Interval], 0)

			---------------------------------------------------
			-- make entries in interval tracking table
			-- for long intervals
			---------------------------------------------------

			INSERT INTO T_Run_Interval( ID,
			                            Instrument,
			                            Start,
			                            [Interval] )
			SELECT ID,
			       @instrumentName,
			       Time_End,
			       [Interval]
			FROM #Tmp_Durations
			WHERE NOT ID IN ( SELECT ID
			                  FROM T_Run_Interval ) AND
			      [Interval] > @maxNormalInterval
			      
			---------------------------------------------------
			-- delete "short" long intervals
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
	END CATCH
	
	If @infoOnly <> 0 and @myError <> 0
		Print @message

	RETURN @myError

GO
GRANT VIEW DEFINITION ON [dbo].[UpdateDatasetInterval] TO [DDL_Viewer] AS [dbo]
GO
