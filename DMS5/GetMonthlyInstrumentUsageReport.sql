/****** Object:  StoredProcedure [dbo].[GetMonthlyInstrumentUsageReport] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE dbo.GetMonthlyInstrumentUsageReport
/****************************************************
**
**  Desc: 
**    Create a monthly usage report for given  
**    Instrument, year, and month 
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**	Auth:	grk
**	Date:	03/06/2012 
**			03/06/2012 grk - changed @mode to @outputFormat
**			03/06/2012 grk - added long interval comment to 'detail' output format
**			03/10/2012 grk - added '@OtherNotAvailable'
**			03/15/2012 grk - added 'report' @outputFormat
**			03/20/2012 grk - added users to 'report' @outputFormat
**			03/21/2012 grk - added operator ID for ONSITE interval to 'report' @outputFormat
**			08/21/2012 grk - added code to pull comment from dataset
**			08/28/2012 grk - added code to clear comment from ONSITE capability type
**			08/31/2012 grk - now removing 'Auto-switched dataset type ...' text from dataset comments
**			09/11/2012 grk - added percent column to 'rollup' mode
**			09/18/2012 grk - handling "Operator" and "PropUser" prorata comment fields
**			02/23/2016 mem - Add set XACT_ABORT on
**    
** Pacific Northwest National Laboratory, Richland, WA
** Copyright 2009, Battelle Memorial Institute
*****************************************************/
(
	@instrument VARCHAR(64),
	@year VARCHAR(12),
	@month VARCHAR(12),
	@outputFormat varchar(12) = 'details', -- 'details', 'rollup', 'check', 'report' 
	@message varchar(512) output
)
As
	Set XACT_ABORT, nocount on

	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0

	set @message = ''

	---------------------------------------------------
	---------------------------------------------------
	BEGIN TRY 

		---------------------------------------------------
		-- get maximum time available in month
		---------------------------------------------------

		DECLARE @date DATETIME = CONVERT(DATE, @month + '/1/' + @year, 101)
		DECLARE @daysInMonth int
		SET @daysInMonth =  DAY(DATEADD (m, 1, DATEADD (d, 1 - DAY(@date), @date)) - 1) 
		DECLARE @minutesInMonth INT = @daysInMonth * 1440

		---------------------------------------------------
		-- create temporary table to contain report data
		-- and populate with datasets in for the specified 
		-- instrument and reporting month
		-- (the UDF returns intervals adjusted to monthly boundaries)
		---------------------------------------------------

		CREATE TABLE #TR (
			ID INT,
			[Type] VARCHAR(128),
			Start DATETIME,
			Duration INT,
			[Interval] INT,
			Proposal varchar(32) NULL,
			[Usage] varchar(32) NULL,
			[UsageID] INT NULL,
			[Normal] TINYINT NULL,
			Comment VARCHAR(4096) NULL,
			Users VARCHAR(1024) NULL,
			Operator VARCHAR(128) NULL
		)

		INSERT INTO #TR (
			ID ,
			[Type],
			Start,
			Duration ,
			[Interval] ,
			Proposal ,
			[UsageID],
			[Usage],
			[Normal]
		)
		SELECT  
			GRTMI.ID ,
			'Dataset' AS [Type],
			GRTMI.Time_Start AS Start,
			GRTMI.Duration ,
			ISNULL(GRTMI.Interval, 0) AS [Interval],
			ISNULL(TRR.RDS_EUS_Proposal_ID, '') AS Proposal,
			TRR.RDS_EUS_UsageType AS UsageID,
			TEUT.Name AS [Usage],
			1
		FROM
			dbo.GetRunTrackingMonthlyInfo(@instrument, @year, @month, '') AS GRTMI
			LEFT OUTER JOIN T_Requested_Run AS TRR ON GRTMI.ID = TRR.DatasetID 
			INNER JOIN T_EUS_UsageType TEUT ON TRR.RDS_EUS_UsageType = TEUT.ID;

		---------------------------------------------------
		-- Pull comments from datasets
		--
		-- The Common Table Expression (CTE) is used to create a cleaned up comment that removes 
		--  text of the form Auto-switched dataset type from HMS-MSn to HMS-HCD-HMSn on 2012-01-01
		---------------------------------------------------

		WITH DSCommentClean (Dataset_ID, Comment)
		AS ( SELECT Dataset_ID, REPLACE(DS_Comment, TextToRemove, '') AS Comment
			 FROM ( SELECT Dataset_ID, DS_Comment,
						   SUBSTRING(DS_Comment, AutoSwitchIndex, AutoSwitchIndex + AutoSwitchIndexEnd) AS TextToRemove
					FROM ( SELECT Dataset_ID, DS_Comment, AutoSwitchIndex,
								  PATINDEX('%[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]%', AutoSwitchTextPortion) + 10 AS AutoSwitchIndexEnd
							FROM ( SELECT Dataset_ID, DS_Comment, AutoSwitchIndex,
							              SUBSTRING(DS_Comment, AutoSwitchIndex, 200) AS AutoSwitchTextPortion
									FROM ( SELECT Dataset_ID, DS_Comment,
									              PATINDEX('%Auto-switched dataset type from%to%on [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]%', DS_comment) AS AutoSwitchIndex
											FROM T_Dataset DS INNER JOIN 
											     #TR ON DS.Dataset_ID = #TR.ID
										  ) FilterQ
									WHERE AutoSwitchIndex > 0 
								  ) FilterQ2 
						   ) FilterQ3 
				    ) FilterQ4
		  )
     	UPDATE #TR
		SET Comment = IsNull(DSCommentClean.Comment, IsNull(TDS.DS_comment, ''))
		FROM #TR INNER JOIN
		     T_Dataset AS TDS ON TDS.Dataset_ID = #TR.ID LEFT OUTER JOIN 
		     DSCommentClean ON DSCommentClean.Dataset_ID = #TR.ID;

		---------------------------------------------------
		-- make a temp table to work with long intervals
		-- and populate it with long intervals for the datasets 
		-- that were added to the temp report table
		---------------------------------------------------

		CREATE TABLE #TI (
			  ID INT ,
			  Start DATETIME,
			  Breakdown XML NULL,
			  Comment VARCHAR(4096) NULL
		)

		INSERT into #TI (
			ID, 
			Start,
			Breakdown,
			Comment
		)
		SELECT  
				TRI.ID,
				TRI.START,
				TRI.Usage,
				TRI.Comment
		FROM  T_Run_Interval TRI
				INNER JOIN #TR ON TRI.ID = #TR.ID


		---------------------------------------------------
		-- mark datasets in temp report table 
		-- that have long intervals 
		---------------------------------------------------

		UPDATE #TR
		SET 
			[Normal] = 0
		WHERE #TR.ID IN (SELECT ID FROM #TI)

		---------------------------------------------------
		-- make temp table to hold apportioned long interval values
		---------------------------------------------------

		CREATE TABLE #TQ (
			ID INT,
			Start DATETIME,
			[Interval] INT,
			Proposal varchar(32) NULL,
			[Usage] varchar(32) NULL,
			Comment VARCHAR(4096) NULL,
			Users VARCHAR(1024) NULL,
			Operator VARCHAR(128) NULL
		)

		---------------------------------------------------
		-- extract long interval apportionments from XML
		-- and use to save apportioned intervals to the temp table
		---------------------------------------------------

		INSERT INTO #TQ (ID , Start , [Interval] , Proposal , [Usage], Comment)
		SELECT 
			#TI.ID,
			#TI.Start,
			CONVERT(FLOAT, ISNULL(xmlNode.value('@Broken', 'varchar(32)'), '0')) * #TR.[Interval] / 100   AS [Interval],
			'' AS Proposal,
			'BROKEN' AS USAGE,
			#TI.Comment
		FROM #TI
		INNER JOIN #TR ON #TR.ID = #TI.ID
				CROSS APPLY BreakDown.nodes('//u') AS R ( xmlNode )


		INSERT INTO #TQ (ID , Start , [Interval] , Proposal , [Usage], Comment)
		SELECT 
			#TI.ID,
			#TI.Start,
			CONVERT(FLOAT, ISNULL(xmlNode.value('@Maintenance', 'varchar(32)'), '0')) * #TR.[Interval] / 100   AS [Interval],
			'' AS Proposal,
			'MAINTENANCE' AS Usage,
			#TI.Comment
		FROM #TI
		INNER JOIN #TR ON #TR.ID = #TI.ID
				CROSS APPLY BreakDown.nodes('//u') AS R ( xmlNode )

		INSERT INTO #TQ (ID , Start, [Interval] , Proposal , [Usage], Comment)
		SELECT 
			#TI.ID,
			#TI.Start,
			CONVERT(FLOAT, ISNULL(xmlNode.value('@OtherNotAvailable', 'varchar(32)'), '0')) * #TR.[Interval] / 100   AS [Interval],
			'' AS Proposal,
			'UNAVAILABLE' AS Usage,
			#TI.Comment
		FROM #TI
		INNER JOIN #TR ON #TR.ID = #TI.ID
				CROSS APPLY BreakDown.nodes('//u') AS R ( xmlNode )

		INSERT INTO #TQ (ID , Start, [Interval] , Proposal , [Usage], Comment)
		SELECT 
			#TI.ID,
			#TI.Start,
			CONVERT(FLOAT, ISNULL(xmlNode.value('@StaffNotAvailable', 'varchar(32)'), '0')) * #TR.[Interval] / 100   AS [Interval],
			'' AS Proposal,
			'UNAVAIL_STAFF' AS Usage,
			#TI.Comment
		FROM #TI
		INNER JOIN #TR ON #TR.ID = #TI.ID
				CROSS APPLY BreakDown.nodes('//u') AS R ( xmlNode )

		INSERT INTO #TQ (ID , Start, [Interval], Operator , Proposal , [Usage], Comment)
		SELECT 
			#TI.ID,
			#TI.Start,
			CONVERT(FLOAT, ISNULL(xmlNode.value('@CapDev', 'varchar(32)'), '0')) * #TR.[Interval] / 100   AS [Interval],
			xmlNode.value('@Operator', 'varchar(32)') AS Operator,	
			'' AS Proposal,
			'CAP_DEV' AS Usage,
			#TI.Comment
		FROM #TI
		INNER JOIN #TR ON #TR.ID = #TI.ID
				CROSS APPLY BreakDown.nodes('//u') AS R ( xmlNode )

		INSERT INTO #TQ (ID , Start, [Interval] , Proposal , [Usage], Comment)
		SELECT 
			#TI.ID,
			#TI.Start,
			CONVERT(FLOAT, ISNULL(xmlNode.value('@InstrumentAvailable', 'varchar(32)'), '0')) * #TR.[Interval] / 100   AS [Interval],
			'' AS Proposal,
			'AVAILABLE' AS Usage,
			#TI.Comment
		FROM #TI
		INNER JOIN #TR ON #TR.ID = #TI.ID
				CROSS APPLY BreakDown.nodes('//u') AS R ( xmlNode )

		INSERT INTO #TQ (ID , Start, [Interval] , Proposal, Users , [Usage], Comment)
		SELECT 
			#TI.ID,
			#TI.Start,
			CONVERT(FLOAT, ISNULL(xmlNode.value('@User', 'varchar(32)'), '0')) * #TR.[Interval] / 100   AS [Interval],
			xmlNode.value('@Proposal', 'varchar(32)') AS Proposal,
			xmlNode.value('@PropUser', 'varchar(32)') AS Users,	
			'ONSITE' AS Usage,
			#TI.Comment
		FROM #TI
		INNER JOIN #TR ON #TR.ID = #TI.ID
				CROSS APPLY BreakDown.nodes('//u') AS R ( xmlNode )


		---------------------------------------------------
		-- Get rid of meaningless apportioned long intervals
		---------------------------------------------------

		DELETE FROM #TQ WHERE [Interval] = 0


		---------------------------------------------------
		-- debug 1		
		---------------------------------------------------                            
		IF @outputFormat = 'debug1'
		BEGIN 
			SELECT * FROM #TQ
		END

		---------------------------------------------------
		-- Clean up unecessary comments
		---------------------------------------------------

		UPDATE #TQ
		SET Comment = ''
		WHERE Usage = 'ONSITE' OR Usage = 'CAP_DEV'

		---------------------------------------------------
		-- add apportioned long intervals to report table
		---------------------------------------------------

		INSERT INTO #TR (
			ID ,
			[Type],
			Start,
			Duration ,
			[Interval] ,
			Proposal ,
			[Usage],
			Comment,
			Users,
			Operator
		)
		SELECT    
			ID ,
			'Interval' AS [Type] ,
			Start ,
			0 AS Duration ,
			Interval ,
			Proposal ,
			Usage,
			Comment,
			Users,
			Operator
		FROM      #TQ

		---------------------------------------------------
		-- debug 2		
		---------------------------------------------------                            
		IF @outputFormat = 'debug2'
		BEGIN 
			SELECT * FROM #TR
		END

		---------------------------------------------------
		-- zero interval values for datasets with long intervals
		---------------------------------------------------

		UPDATE #TR
		SET [Interval] = 0
		WHERE [Type] = 'Dataset' AND [Normal] = 0

		---------------------------------------------------
		-- translate remaining DMS usage categories
		-- to EMSL usage categories
		---------------------------------------------------

		UPDATE #TR
		SET [Usage] = 'ONSITE'
		WHERE [Usage] = 'USER'

		---------------------------------------------------
		-- remove artifacts
		---------------------------------------------------

		DELETE FROM #TR WHERE Duration = 0 AND [Interval] = 0

		---------------------------------------------------
		-- add interval to duration for normal datasets
		---------------------------------------------------

		UPDATE #TR
		SET 
			Duration = Duration + [Interval],
			[Interval] = 0
		WHERE [Type] = 'Dataset' AND [Normal] > 0

		---------------------------------------------------
		-- debug
		--SELECT * FROM #TR ORDER BY Start
		--SELECT * FROM #TQ ORDER BY Start
		--SELECT * FROM #TI
		--SELECT * FROM #TF
		---------------------------------------------------
		-- debug 3	
		---------------------------------------------------                            
		IF @outputFormat = 'debug3'
		BEGIN 
			SELECT * FROM #TR
		END

		---------------------------------------------------
		-- provide output report according to mode
		---------------------------------------------------

		---------------------------------------------------
		-- provide report format
		---------------------------------------------------

		IF @outputFormat = 'report'
		BEGIN 
			-- look up EMSL instrument ID
			DECLARE @emsl_instrument_id INT 
			SELECT   @emsl_instrument_id = TEDIM.EUS_Instrument_ID
			FROM     T_Instrument_Name AS TIN
					LEFT OUTER JOIN T_EMSL_DMS_Instrument_Mapping AS TEDIM ON TIN.Instrument_ID = TEDIM.DMS_Instrument_ID
			WHERE    ( TIN.IN_name = @instrument )

			-- get user lists for datasets
			UPDATE #TR SET Users = '', Operator = ''
			WHERE #TR.[Type] = 'Dataset'
			--
			UPDATE #TR
			SET Operator = TEU.PERSON_ID
			FROM #TR 
			INNER JOIN T_Dataset AS TD ON #TR.ID = TD.Dataset_ID
					INNER JOIN T_Users AS TU ON TD.DS_Oper_PRN = TU.U_PRN
					INNER JOIN T_EUS_Users AS TEU ON TU.U_HID = TEU.HID
			WHERE #TR.[Type] = 'Dataset'

			-- get operator user ID for datasets
			UPDATE  #TR
			SET Users =  dbo.GetRequestedRunEUSUsersList(TRR.ID, 'I')
			FROM #TR
			INNER JOIN dbo.T_Requested_Run TRR ON #TR.ID = TRR.DatasetID
			WHERE #TR.[Type] = 'Dataset'

			-- get operator user ID for ONSITE intervals
			UPDATE  #TR
			SET Operator =  TEU.PERSON_ID
			FROM #TR
			INNER JOIN dbo.T_Run_Interval TRI ON TRI.ID = #TR.ID
					INNER JOIN T_Users AS TU ON TRI.Entered_By = TU.U_PRN
					INNER JOIN T_EUS_Users AS TEU ON TU.U_HID = TEU.HID			
			WHERE #TR.[Type] = 'Interval' AND #TR.[Usage] = 'ONSITE'

			-- output report rows
			SELECT 
				@instrument AS Instrument,
				@emsl_instrument_id AS EMSL_Inst_ID,
				CONVERT(VARCHAR(32), [Start], 100) AS [Start],
				[Type],
				CASE WHEN [Type] = 'Interval' THEN [Interval] ELSE Duration END AS [Minutes],
				Proposal ,
				[Usage] ,
				Users,
				Operator,
				ISNULL(Comment, '') AS Comment,
				@year AS [Year],
				@month AS [Month],
				#TR.ID 
			 FROM #TR 
			 ORDER BY Start
		END 

		---------------------------------------------------
		-- provide all the details
		---------------------------------------------------

		IF @outputFormat = 'details' OR @outputFormat = '' -- default mode
		BEGIN 
			SELECT 
				CONVERT(VARCHAR(32), [Start], 100) AS [Start],
				[Type],
				CASE WHEN [Type] = 'Interval' THEN [Interval] ELSE Duration END AS [Minutes],
				Proposal ,
				[Usage] ,
				ISNULL(Comment, '') AS Comment,
				ID 
			 FROM #TR ORDER BY Start
		END 

		---------------------------------------------------
		-- rollup by type, category, and propsal
		---------------------------------------------------

		IF @outputFormat = 'rollup'
		BEGIN 
			SELECT  
				[Type],
				[Minutes],
				CONVERT(DECIMAL(10,1), CONVERT(FLOAT, [Minutes])/@minutesInMonth * 100.0) AS [Percentage],
				[Usage],
				Proposal
			FROM 
			(					          
			SELECT 
				[Type],
				SUM(CASE WHEN [Type] = 'Interval' THEN [Interval] ELSE Duration END) AS [Minutes],
				[Usage],
				Proposal
			FROM #TR
			GROUP BY [Type], [Usage], Proposal
			) TQZ
			ORDER BY [Type], [Usage], Proposal
		END	

		---------------------------------------------------
		-- check grand totals against available
		---------------------------------------------------

		IF @outputFormat = 'check'
		BEGIN 
			SELECT 
				@minutesInMonth AS 'Available',
				SUM(Duration) AS Duration,
				SUM([Interval]) AS [Interval],
				SUM (Duration + INTERVAL) AS [Total],
				CONVERT(DECIMAL(10,1), CONVERT(FLOAT, SUM (Duration + INTERVAL))/@minutesInMonth * 100.0) AS [Percentage]
			FROM #TR
		END 	 

	---------------------------------------------------
	---------------------------------------------------
	END TRY
	BEGIN CATCH 
		EXEC FormatErrorMessage @message output, @myError output

		-- rollback any open transactions
		IF (XACT_STATE()) <> 0
			ROLLBACK TRANSACTION;
	END CATCH

	return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[GetMonthlyInstrumentUsageReport] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[GetMonthlyInstrumentUsageReport] TO [DMS2_SP_User] AS [dbo]
GO
