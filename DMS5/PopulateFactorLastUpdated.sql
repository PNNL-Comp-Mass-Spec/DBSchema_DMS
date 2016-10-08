/****** Object:  StoredProcedure [dbo].[PopulateFactorLastUpdated] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure dbo.PopulateFactorLastUpdated
/****************************************************
** 
**	Desc:	Populates the Last_Updated column in table T_Factors using T_Factor_Log
**		
**	Return values: 0: success, otherwise, error code
**
**	Auth:	mem
**	Date:	10/06/2016 mem - Initial version
**    
*****************************************************/
(
	@infoOnly tinyint = 1,
	@dateFilterStart date = null,
	@dateFilterEnd date = null,
	@message varchar(512) = '' output
)
As
	set nocount on
	
	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0

	Declare @continue tinyint
	Declare @validFactorEntries int = 0
	
	Declare @eventID int
	Declare @eventIDEnd int
	Declare @changeDate smalldatetime
	Declare @factorChanges varchar(max)
	
	-----------------------------------------------------------
	-- Create some temporary tables
	-----------------------------------------------------------
	
	CREATE TABLE #Tmp_FactorUpdates 
	(
		RequestID int not null,
		FactorType varchar(128) null,
		FactorName varchar(128) null,
		FactorValue varchar(128) null,
		ValidFactor tinyint not null
	)
	
	CREATE CLUSTERED INDEX #IX_Tmp_FactorUpdates ON #Tmp_FactorUpdates (RequestID)
	
	CREATE TABLE #Tmp_FactorLastUpdated 
	(
		RequestID int not null,
		FactorName varchar(128) not null,
		Last_Updated smalldatetime not null
	)
	
	CREATE CLUSTERED INDEX #IX_Tmp_FactorLastUpdated ON #Tmp_FactorLastUpdated (RequestID, FactorName)
	
	-----------------------------------------------------------
	-- Validate the inputs
	-----------------------------------------------------------
	
	Set @infoOnly = IsNull(@infoOnly, 1)
	Set @message = ''
	
	If @dateFilterStart Is Null And @dateFilterEnd Is Null
	Begin
		Set @eventID = -1
		
		SELECT @eventIDEnd = Max(Event_ID) + 1
		FROM T_Factor_Log
		
		Set @eventIDEnd = IsNull(@eventIDEnd, 1000)
		
	End
	Else
	Begin
		If Not @dateFilterStart Is Null And @dateFilterEnd Is Null
			Set @dateFilterEnd = '9999-01-01'
		
		If @dateFilterStart Is Null And Not @dateFilterEnd Is Null
			Set @dateFilterStart = '0001-01-01'

		Set @message = 'Finding Factor_Log entries between ' + Convert(varchar(30), @dateFilterStart, 121) + ' And ' + Convert(varchar(30), DateAdd(day, 1, @dateFilterEnd), 121)
		If @infoOnly <> 0
			Select @message as Filter_Message
		Else
			Print @message
			
		SELECT @eventID = Min(Event_ID) - 1
		FROM T_Factor_Log
		WHERE (changed_on BETWEEN @dateFilterStart AND DateAdd(day, 1, @dateFilterEnd))
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		
		SELECT @eventIDEnd = Max(Event_ID)
		FROM T_Factor_Log
		WHERE (changed_on BETWEEN @dateFilterStart AND DateAdd(day, 1, @dateFilterEnd))
		
		Set @message = ''
	End

	-----------------------------------------------------------
	-- Step through the rows in T_Factor_Log
	-----------------------------------------------------------
	
	Set @Continue = 1
	While @Continue = 1
	Begin -- <a>
		-- Find the next row entry for a requested run factor update
		--
		SELECT TOP 1 @eventID = Event_ID, @changeDate = Cast(changed_on as smalldatetime), @factorChanges = changes
		FROM T_Factor_Log
		WHERE Event_ID > @eventID AND changes like '<r i%'
		ORDER BY Event_ID
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		
		If @myRowCount = 0 Or @eventID > @eventIDEnd
		Begin
			Set @Continue = 0			
		End
		Else
		Begin -- <b>
			
			DECLARE @xml xml= Cast(@factorChanges AS xml)

			-- Uncomment to preview the raw XML
			-- print @factorChanges

			TRUNCATE TABLE #Tmp_FactorUpdates
			
			INSERT INTO #Tmp_FactorUpdates(RequestID, FactorType, FactorName, FactorValue, ValidFactor)
			SELECT  
				Tbl.Col.value('@i', 'int') AS RequestID,  
				Tbl.Col.value('@t', 'varchar(128)') AS FactorType,
				Tbl.Col.value('@f', 'varchar(128)') AS FactorName,
				Tbl.Col.value('@v', 'varchar(128)') AS FactorValue,
				0 AS ValidFactor
			FROM   @xml.nodes('//r') Tbl(Col);
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount	

			-- Look for valid factor update data
			--
			UPDATE #Tmp_FactorUpdates
			SET ValidFactor = 1
			FROM #Tmp_FactorUpdates 
			WHERE NOT IsNull(FactorType, '') IN ('Block', 'Run Order') AND 
					Not FactorName Is Null
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount	

			If @myRowCount > 0
			Begin -- <c>
				Set @validFactorEntries = @validFactorEntries + 1
				
				/*
				 * Uncomment to debug
				If @infoOnly <> 0 AND @validFactorEntries <= 3
				Begin
					SELECT RequestID, FactorName 
					FROM #Tmp_FactorUpdates 
					WHERE ValidFactor = 1
					ORDER BY RequestID, FactorName
				End
				*/
				
				-- Merge the changes into #Tmp_FactorLastUpdated
				MERGE #Tmp_FactorLastUpdated AS t
				USING (SELECT RequestID, FactorName 
					FROM #Tmp_FactorUpdates 
					WHERE ValidFactor = 1) as s
				ON ( t.RequestID = s.RequestID And t.FactorName = s.FactorName)
				WHEN MATCHED
				THEN UPDATE SET 
					[Last_Updated] = @changeDate
				WHEN NOT MATCHED BY TARGET THEN
					INSERT(RequestID, FactorName, Last_Updated)
					VALUES(s.RequestID, s.FactorName, @changeDate)
				;
			End -- </c>
		End -- </b>
	End -- </a>

	If @infoOnly <> 0
	Begin
		SELECT Target.*,
		       Src.Last_Updated AS Last_Updated_New
		FROM T_Factor Target
		     INNER JOIN #Tmp_FactorLastUpdated Src
		       ON Target.[Type] = 'Run_Request' AND
		          Target.TargetID = Src.RequestID AND
		          Target.Name = Src.FactorName
		WHERE Src.Last_Updated <> Target.Last_Updated
		ORDER BY Target.TargetID, Target.Name
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount

	End
	Else
	Begin
		UPDATE T_Factor
		SET Last_Updated = Src.Last_Updated
		FROM T_Factor Target
		     INNER JOIN #Tmp_FactorLastUpdated Src
		       ON Target.[Type] = 'Run_Request' AND
		          Target.TargetID = Src.RequestID AND
		          Target.Name = Src.FactorName
		WHERE Src.Last_Updated <> Target.Last_Updated
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		
		Set @message = 'Updated Last_Updated for ' + Cast(@myRowCount as varchar(12)) + ' rows in T_Factor'
		SELECT @message AS Message
	End

	Print 'Parsed ' + cast(@validFactorEntries as varchar(12)) + ' factor log records'
	
	-----------------------------------------------------------
	-- Exit
	-----------------------------------------------------------
Done:
	return @myError

GO
