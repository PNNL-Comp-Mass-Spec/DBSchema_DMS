/****** Object:  StoredProcedure [dbo].[SynchronizeManagerStatus] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE dbo.SynchronizeManagerStatus
/****************************************************
**
**  Desc:	Updates T_Processor_Status for items with a value defined for Remote_Status_Location
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters:
**
**	Auth:	mem
**			06/02/2009 mem - Initial version
**
*****************************************************/
(
	@infoOnly tinyint,
	@message varchar(512)='' output
)
As
	set nocount on

	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0

	Declare @S varchar(1024)
	Declare @Continue tinyint
	Declare @EntryID int
	Declare @RemoteLocation varchar(256)
	
	---------------------------------------------------
	-- Validate the inputs; clear the outputs
	---------------------------------------------------

	Set @infoOnly = IsNull(@infoOnly, 0)
	Set @message = ''

	---------------------------------------------------
	-- Create two temporary tables
	---------------------------------------------------
	
	CREATE TABLE #Tmp_RemoteLocations (
		EntryID int identity(1,1),
		RemoteLocation varchar(256) NOT NULL
	)

	CREATE TABLE #Tmp_StatusInfo(
		Processor_Name varchar(128) NOT NULL,
		Status_Code int NOT NULL,
		Job int NULL,
		Job_Step int NULL,
		Step_Tool varchar(128) NULL,
		Dataset varchar(256) NULL,
		Duration_Hours real NULL,
		Progress real NULL,
		DS_Scan_Count int NULL,
		Most_Recent_Job_Info varchar(256) NULL,
		Most_Recent_Log_Message varchar(1024) NULL,
		Most_Recent_Error_Message varchar(1024) NULL,
		Status_Date datetime NOT NULL
	)
	
	---------------------------------------------------
	-- Populate a temporary table with the alternate locations to poll
	---------------------------------------------------
	INSERT INTO #Tmp_RemoteLocations (RemoteLocation)
	SELECT DISTINCT Remote_Status_Location
	FROM dbo.T_Processor_Status
	WHERE (NOT (ISNULL(Remote_Status_Location, '') = ''))
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error populating #Tmp_RemoteLocations'
		goto Done
	end
	
	if @myRowCount = 0
	Begin
		set @message = 'No processors have status being posted remotely; nothing to do'
	End
	Else
	Begin -- <a>
		---------------------------------------------------
		-- Loop through the entries in #Tmp_RemoteLocations
		---------------------------------------------------
		
		Set @Continue = 1
		Set @EntryID = -1
		
		While @Continue <> 0
		Begin -- <b>
			SELECT TOP 1 @RemoteLocation = RemoteLocation,
			             @EntryID = EntryID
			FROM #Tmp_RemoteLocations
			WHERE EntryID > @EntryID
			ORDER BY EntryID
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			
			
			If @myRowCount = 0
				Set @Continue = 0
			Else
			Begin -- <c>			
				Set @S = ''
				
				Set @S = @S + ' INSERT INTO #Tmp_StatusInfo (Processor_Name, Status_Code, Job, Job_Step, Step_Tool, '
				Set @S = @S +     ' Dataset, Duration_Hours, Progress, DS_Scan_Count, '
				Set @S = @S +     ' Most_Recent_Job_Info, Most_Recent_Log_Message, '
				Set @S = @S +     ' Most_Recent_Error_Message, Status_Date)'
				Set @S = @S + ' SELECT Processor_Name, Status_Code, Job, Job_Step, Step_Tool, '
				Set @S = @S +     ' Dataset, Duration_Hours, Progress, DS_Scan_Count, '
				Set @S = @S +     ' Most_Recent_Job_Info, Most_Recent_Log_Message, '
				Set @S = @S +     ' Most_Recent_Error_Message, Status_Date'
				Set @S = @S + ' FROM ' + @RemoteLocation
				Set @S = @S + ' WHERE Processor_Name IN (SELECT Processor_Name FROM T_Processor_Status WHERE Remote_Status_Location = ''' + @RemoteLocation + ''')'

				If @InfoOnly <> 0
					Print @S
				
				Exec (@S)
				
				If @InfoOnly <> 0
					SELECT *
					FROM #Tmp_StatusInfo
					ORDER BY Processor_Name
				Else
					UPDATE T_Processor_Status
					SET Status_Code = Src.Status_Code,
						Job = Src.Job,
						Job_Step = Src.Job_Step,
						Step_Tool = Src.Step_Tool,
						Dataset = Src.Dataset,
						Duration_Hours = Src.Duration_Hours,
						Progress = Src.Progress,
						DS_Scan_Count = Src.DS_Scan_Count,
						Most_Recent_Job_Info = Src.Most_Recent_Job_Info,
						Most_Recent_Log_Message = Src.Most_Recent_Log_Message,
						Most_Recent_Error_Message = Src.Most_Recent_Error_Message,
						Status_Date = Src.Status_Date
					FROM #Tmp_StatusInfo SRC
						INNER JOIN T_Processor_Status Target
						ON Target.Processor_Name = Src.Processor_Name
					--
					SELECT @myError = @@error, @myRowCount = @@rowcount

			End -- </c>
		End -- </b>		
	End -- </a>

	---------------------------------------------------
	-- Exit
	---------------------------------------------------
	--
Done:
	--
	return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[SynchronizeManagerStatus] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[SynchronizeManagerStatus] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[SynchronizeManagerStatus] TO [PNL\D3M580] AS [dbo]
GO
