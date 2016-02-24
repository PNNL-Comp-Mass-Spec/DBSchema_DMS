/****** Object:  StoredProcedure [dbo].[UpdateManagerAndTaskStatusXML] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE UpdateManagerAndTaskStatusXML
/****************************************************
**
**	Desc:
**  Update processor status from concatenated list
**  of XML status messages
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters:
**
**	Auth:	grk
**			08/20/2009 grk - Initial release
**			08/29/2009 mem - Now converting Duration_Minutes to Duration_Hours
**						   - Added Try/Catch error handling
**			08/31/2009 mem - Switched to running a bulk Insert and bulk Update instead of a Delete then Bulk Insert
**			05/04/2015 mem - Added Process_ID
**			11/20/2015 mem - Added ProgRunner_ProcessID and ProgRunner_CoreUsage
**						   - Added parameter @debugMode
**			02/23/2016 mem - Add set XACT_ABORT on
**
*****************************************************/
(
    @parameters text = '',
    @result varchar(4096) output,
    @debugMode tinyint = 0
)
As
	Set XACT_ABORT, nocount on

	declare @myError int
	declare @myRowCount int

	set @myError = 0
	set @myRowCount = 0
	
	set @result = ''
	Set @debugMode = IsNull(@debugMode, 0)
	
	declare @temp varchar(2048) = ''

	declare @message varchar(512)
	
	declare @CallingProcName varchar(128)
	declare @CurrentLocation varchar(128)
	Set @CurrentLocation = 'Start'

	Begin Try

		---------------------------------------------------
		--  Extract parameters from XML input
		---------------------------------------------------

		declare @paramXML xml
		set @paramXML = @parameters

		If @debugMode <> 0
		Begin
			-- Use some test data
			SET @paramXML ='<Root><Manager><MgrName>TestManager1</MgrName><MgrStatus>Stopped</MgrStatus><LastUpdate>8/20/2009 10:39:21 AM</LastUpdate><LastStartTime>8/20/2009 10:39:20 AM</LastStartTime><CPUUtilization>100.0</CPUUtilization><FreeMemoryMB>490.0</FreeMemoryMB><ProcessID>5555</ProcessID><ProgRunnerProcessID>50000</ProgRunnerProcessID><ProgRunnerCoreUsage>5.01</ProgRunnerCoreUsage><RecentErrorMessages><ErrMsg /></RecentErrorMessages></Manager><Task><Tool /><Status>No Task</Status><Duration>0.00</Duration><DurationMinutes>0.0</DurationMinutes><Progress>0.00</Progress><CurrentOperation /><TaskDetails><Status>No Task</Status><Job>0</Job><Step>0</Step><Dataset /><MostRecentLogMessage>Closing manager.</MostRecentLogMessage><MostRecentJobInfo /><SpectrumCount>0</SpectrumCount></TaskDetails></Task></Root>
							<Root><Manager><MgrName>TestManager2</MgrName><MgrStatus>Running</MgrStatus><LastUpdate>8/20/2009 10:39:35 AM</LastUpdate><LastStartTime>8/20/2009 10:23:11 AM</LastStartTime><CPUUtilization>28.0</CPUUtilization><FreeMemoryMB>402.0</FreeMemoryMB><ProcessID>4444</ProcessID><RecentErrorMessages><ErrMsg /></RecentErrorMessages></Manager><Task><Tool>Sequest, Step 3</Tool><Status>Running</Status><Duration>0.27</Duration><DurationMinutes>16.4</DurationMinutes><Progress>8.34</Progress><CurrentOperation /><TaskDetails><Status>Running Tool</Status><Job>525282</Job><Step>3</Step><Dataset>Mcq_CynoLung_norm_11_7Apr08_Phoenix_08-03-01</Dataset><MostRecentLogMessage /><MostRecentJobInfo>Job 525282; Sequest, Step 3; Mcq_CynoLung_norm_11_7Apr08_Phoenix_08-03-01; 8/20/2009 10:23:11 AM</MostRecentJobInfo><SpectrumCount>26897</SpectrumCount></TaskDetails></Task></Root>
							<Root><Manager><MgrName>TestManager3</MgrName><MgrStatus>Running</MgrStatus><LastUpdate>8/20/2009 10:39:30 AM</LastUpdate><LastStartTime>8/19/2009 10:02:28 PM</LastStartTime><CPUUtilization>14.0</CPUUtilization><FreeMemoryMB>3054.0</FreeMemoryMB><ProcessID>3333</ProcessID><ProgRunnerProcessID>50010</ProgRunnerProcessID><ProgRunnerCoreUsage>1.99</ProgRunnerCoreUsage><RecentErrorMessages><ErrMsg /></RecentErrorMessages></Manager><Task><Tool>Sequest, Step 3</Tool><Status>Running</Status><Duration>12.62</Duration><DurationMinutes>757.0</DurationMinutes><Progress>74.46</Progress><CurrentOperation /><TaskDetails><Status>Running Tool</Status><Job>525235</Job><Step>3</Step><Dataset>PL-1_pro_B_5Aug09_Owl_09-05-10</Dataset><MostRecentLogMessage /><MostRecentJobInfo>Job 525235; Sequest, Step 3; PL-1_pro_B_5Aug09_Owl_09-05-10; 8/19/2009 10:02:28 PM</MostRecentJobInfo><SpectrumCount>50229</SpectrumCount></TaskDetails></Task></Root>
							<Root><Manager><MgrName>TestManager4</MgrName><MgrStatus>Stopped</MgrStatus><LastUpdate>8/20/2009 10:39:23 AM</LastUpdate><LastStartTime>8/20/2009 10:39:22 AM</LastStartTime><CPUUtilization>25.0</CPUUtilization><FreeMemoryMB>917.0</FreeMemoryMB><ProcessID>2222</ProcessID><RecentErrorMessages><ErrMsg>8/18/2009 02:44:31, Pub-02-2: No spectra files created, Job 524793, Dataset QC_Shew_09_02-pt5-e_18Aug09_Griffin_09-07-13</ErrMsg></RecentErrorMessages></Manager><Task><Tool /><Status>No Task</Status><Duration>0.00</Duration><DurationMinutes>0.0</DurationMinutes><Progress>0.00</Progress><CurrentOperation /><TaskDetails><Status>No Task</Status><Job>0</Job><Step>0</Step><Dataset /><MostRecentLogMessage>Closing manager.</MostRecentLogMessage><MostRecentJobInfo /><SpectrumCount>0</SpectrumCount></TaskDetails></Task></Root>
							<Root><Manager><MgrName>TestManager5</MgrName><MgrStatus>Running</MgrStatus><LastUpdate>8/20/2009 10:39:31 AM</LastUpdate><LastStartTime>8/20/2009 10:24:05 AM</LastStartTime><CPUUtilization>30.0</CPUUtilization><FreeMemoryMB>415.0</FreeMemoryMB><ProcessID>1111</ProcessID><RecentErrorMessages><ErrMsg /></RecentErrorMessages></Manager><Task><Tool>Sequest, Step 3</Tool><Status>Running</Status><Duration>0.26</Duration><DurationMinutes>15.4</DurationMinutes><Progress>9.88</Progress><CurrentOperation /><TaskDetails><Status>Running Tool</Status><Job>525283</Job><Step>3</Step><Dataset>Mcq_CynoLung_norm_12_7Apr08_Phoenix_08-03-01</Dataset><MostRecentLogMessage /><MostRecentJobInfo>Job 525283; Sequest, Step 3; Mcq_CynoLung_norm_12_7Apr08_Phoenix_08-03-01; 8/20/2009 10:24:05 AM</MostRecentJobInfo><SpectrumCount>27664</SpectrumCount></TaskDetails></Task></Root>
							<Root><Manager><MgrName>TestManager6</MgrName><MgrStatus>Running</MgrStatus><LastUpdate>8/20/2009 10:39:30 AM</LastUpdate><LastStartTime>8/19/2009 10:24:32 PM</LastStartTime><CPUUtilization>33.0</CPUUtilization><FreeMemoryMB>1133.0</FreeMemoryMB><ProcessID>6666</ProcessID><ProgRunnerProcessID>50030</ProgRunnerProcessID><ProgRunnerCoreUsage>2</ProgRunnerCoreUsage><RecentErrorMessages><ErrMsg /></RecentErrorMessages></Manager><Task><Tool>Sequest, Step 3</Tool><Status>Running</Status><Duration>12.25</Duration><DurationMinutes>735.0</DurationMinutes><Progress>81.81</Progress><CurrentOperation /><TaskDetails><Status>Running Tool</Status><Job>525236</Job><Step>3</Step><Dataset>PL-1_pro_A_5Aug09_Owl_09-05-10</Dataset><MostRecentLogMessage /><MostRecentJobInfo>Job 525236; Sequest, Step 3; PL-1_pro_A_5Aug09_Owl_09-05-10; 8/19/2009 10:24:32 PM</MostRecentJobInfo><SpectrumCount>44321</SpectrumCount></TaskDetails></Task></Root>'
		End
		
 		---------------------------------------------------
		-- temporary table to hold processor status messages
		---------------------------------------------------
		--
		CREATE TABLE #TPS (
			Processor_Name varchar(128),
			Mgr_Status varchar(50),
			Status_Date varchar(50), -- datetime
			Last_Start_Time varchar(50), -- datetime
			CPU_Utilization varchar(50), -- real
			Free_Memory_MB varchar(50), -- real
			Process_ID varchar(50), -- int
			ProgRunner_ProcessID varchar(50), -- int
			ProgRunner_CoreUsage varchar(50), -- real
			Most_Recent_Error_Message varchar(1024),
			Step_Tool varchar(128),
			Task_Status varchar(50),
			Duration_Minutes varchar(50), -- real
			Progress varchar(50), -- real
			Current_Operation varchar(256),
			Task_Detail_Status varchar(50),
			Job varchar(50), -- int
			Job_Step varchar(50), -- int
			Dataset varchar(256),
			Most_Recent_Log_Message varchar(1024),
			Most_Recent_Job_Info varchar(256),
			Spectrum_Count varchar(50), -- int
			Monitor_Processor tinyint,
			Remote_Status_Location varchar(256)
		)

		CREATE CLUSTERED INDEX #IX_TPS_Processor_Name ON #TPS (Processor_Name)
		
 		---------------------------------------------------
		-- load status messages into temp table
		---------------------------------------------------
		--
		INSERT INTO #TPS
		SELECT 
			xmlNode.value('data((Manager/MgrName)[1])', 'nvarchar(128)') Processor_Name,
			xmlNode.value('data((Manager/MgrStatus)[1])', 'nvarchar(50)') Mgr_Status,
			xmlNode.value('data((Manager/LastUpdate)[1])', 'nvarchar(50)') Status_Date,
			xmlNode.value('data((Manager/LastStartTime)[1])', 'nvarchar(50)') Last_Start_Time,
			xmlNode.value('data((Manager/CPUUtilization)[1])', 'nvarchar(50)') CPU_Utilization,
			xmlNode.value('data((Manager/FreeMemoryMB)[1])', 'nvarchar(50)') Free_Memory_MB,
			
			xmlNode.value('data((Manager/ProcessID)[1])', 'nvarchar(50)') Process_ID,
			xmlNode.value('data((Manager/ProgRunnerProcessID)[1])', 'nvarchar(50)') ProgRunner_ProcessID,
			xmlNode.value('data((Manager/ProgRunnerCoreUsage)[1])', 'nvarchar(50)') ProgRunner_CoreUsage,
			
			xmlNode.value('data((Manager/RecentErrorMessages/ErrMsg)[1])', 'nvarchar(50)') Most_Recent_Error_Message,

			xmlNode.value('data((Task/Tool)[1])', 'nvarchar(128)') Step_Tool,
			xmlNode.value('data((Task/Status)[1])', 'nvarchar(50)') Task_Status,
			xmlNode.value('data((Task/DurationMinutes)[1])', 'nvarchar(50)') Duration_Minutes, -- needs minutes/hours conversion
			xmlNode.value('data((Task/Progress)[1])', 'nvarchar(50)') Progress,
			xmlNode.value('data((Task/CurrentOperation)[1])', 'nvarchar(256)') Current_Operation,

			xmlNode.value('data((Task/TaskDetails/Status)[1])', 'nvarchar(50)') Task_Detail_Status,
			xmlNode.value('data((Task/TaskDetails/Job)[1])', 'nvarchar(50)') Job,
			xmlNode.value('data((Task/TaskDetails/Step)[1])', 'nvarchar(50)') Job_Step,
			xmlNode.value('data((Task/TaskDetails/Dataset)[1])', 'nvarchar(256)')Dataset,
			xmlNode.value('data((Task/TaskDetails/MostRecentLogMessage)[1])', 'nvarchar(1024)') Most_Recent_Log_Message,
			xmlNode.value('data((Task/TaskDetails/MostRecentJobInfo)[1])', 'nvarchar(256)')Most_Recent_Job_Info ,
			xmlNode.value('data((Task/TaskDetails/SpectrumCount)[1])', 'nvarchar(50)')Spectrum_Count,
			'1' as Monitor_Processor,
			'' as Remote_Status_Location
		FROM   @paramXML.nodes('//Root') AS R(xmlNode)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @result = 'Error loading temp table'
			goto Done
		end
		
		If @debugMode <> 0 
		Begin
			SELECT * 
			FROM #TPS
			ORDER BY Processor_Name
		End
		
		set @temp = @temp + 'Messages:' + convert(varchar(12), @myRowCount)

/*
 		---------------------------------------------------
		-- update error message column in temp table
		---------------------------------------------------
		--
		UPDATE #TPS
		SET Most_Recent_Error_Message = Most_Recent_Error_Message + CASE WHEN Most_Recent_Error_Message <> '' THEN + '; ' + ErrMsg ELSE ErrMsg END
		FROM #TPS INNER JOIN
		(
			SELECT 
				xmlNode.value('data((../../MgrName)[1])', 'nvarchar(128)') MgrName,
				xmlNode.value('data((.)[1])', 'nvarchar(1024)') ErrMsg 
			FROM   @paramXML.nodes('//RecentErrorMessages/ErrMsg') AS R(xmlNode)
		) T ON T.MgrName = #TPS.Processor_Name
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @result = 'Error updating temp table'
			goto Done
		end

		set @temp = @temp + ', ErrMsg:' + convert(varchar(12), @myRowCount)


*/

	 	---------------------------------------------------
		-- Update status for existing processors
		---------------------------------------------------
		--
		UPDATE T_Processor_Status
		SET Mgr_Status = Src.Mgr_Status,
		    Status_Date = Src.Status_Date,
		    Last_Start_Time = Src.Last_Start_Time,
		    CPU_Utilization = Src.CPU_Utilization,
		    Free_Memory_MB = Src.Free_Memory_MB,
		    Process_ID = Src.Process_ID,
		    ProgRunner_ProcessID = Src.ProgRunner_ProcessID,
			ProgRunner_CoreUsage = Src.ProgRunner_CoreUsage,
		    Step_Tool = Src.Step_Tool,
		    Task_Status = Src.Task_Status,
		    Duration_Hours = CASE WHEN IsNull(Src.Duration_Minutes, '') = '' Then 0 Else Convert(real, Src.Duration_Minutes) End / 60.0,
		    Progress = CASE WHEN IsNull(Src.Progress, '') = '' Then 0 Else Convert(real, Src.Progress) End,
		    Current_Operation = Src.Current_Operation,
		    Task_Detail_Status = Src.Task_Detail_Status,
		    Job = Src.Job,
		    Job_Step = Src.Job_Step,
		    Dataset = Src.Dataset,
		    Spectrum_Count = Src.Spectrum_Count,
		    Most_Recent_Error_Message = 
		      CASE WHEN Src.Most_Recent_Error_Message <> '' THEN Src.Most_Recent_Error_Message ELSE Target.Most_Recent_Error_Message END,
		    Most_Recent_Log_Message = 
		      CASE WHEN Src.Most_Recent_Log_Message <> ''   THEN Src.Most_Recent_Log_Message   ELSE Target.Most_Recent_Log_Message END,
		    Most_Recent_Job_Info = 
		  CASE WHEN Src.Most_Recent_Job_Info <> ''      THEN Src.Most_Recent_Job_Info      ELSE Target.Most_Recent_Job_Info END
		FROM T_Processor_Status Target
		     INNER JOIN #TPS Src
		       ON Src.Processor_Name = Target.Processor_Name
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
		set @result = 'Error updating existing rows in status table'
			goto Done
		end

		set @temp = @temp + ', Preserved:' + convert(varchar(12), @myRowCount)
	
	 	---------------------------------------------------
		-- Add missing processors to the table
		---------------------------------------------------
		-- FUTURE: Explicit type conversion on number fields?
		--
		INSERT INTO T_Processor_Status (
			Processor_Name,
			Mgr_Status,
			Status_Date,
			Last_Start_Time,
			CPU_Utilization,
			Free_Memory_MB,
			Process_ID,
			ProgRunner_ProcessID,
			ProgRunner_CoreUsage,
			Most_Recent_Error_Message,
			Step_Tool,
			Task_Status,
			Duration_Hours,
			Progress,
			Current_Operation,
			Task_Detail_Status,
			Job,
			Job_Step,
			Dataset,
			Most_Recent_Log_Message,
			Most_Recent_Job_Info,
			Spectrum_Count,
			Monitor_Processor,
			Remote_Status_Location
		)
		SELECT Src.Processor_Name,
		       Src.Mgr_Status,
		       Src.Status_Date,
		       Src.Last_Start_Time,
		       Src.CPU_Utilization,
		       Src.Free_Memory_MB,
		       Src.Process_ID,
		       Src.ProgRunner_ProcessID,
		       Src.ProgRunner_CoreUsage,
		       Src.Most_Recent_Error_Message,
		       Src.Step_Tool,
		       Src.Task_Status,
		       CASE WHEN IsNull(Src.Duration_Minutes, '') = '' Then 0 Else Convert(real, Src.Duration_Minutes) End / 60.0,
		       CASE WHEN IsNull(Src.Progress, '') = '' Then 0 Else Convert(real, Src.Progress) End,
		       Src.Current_Operation,
		       Src.Task_Detail_Status,
		       Src.Job,
		       Src.Job_Step,
		       Src.Dataset,
		       Src.Most_Recent_Log_Message,
		       Src.Most_Recent_Job_Info,
		       Src.Spectrum_Count,
		       Src.Monitor_Processor,
		       Src.Remote_Status_Location
		FROM #TPS Src
		     LEFT OUTER JOIN T_Processor_Status Target
		       ON Src.Processor_Name = Target.Processor_Name
		WHERE Target.Processor_Name IS NULL
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @result = 'Error updating status table'
			goto Done
		end

		set @temp = @temp + ', Inserted:' + convert(varchar(12), @myRowCount)

	End Try
	Begin Catch
		-- Error caught; log the error, then continue at the next section
		Set @CallingProcName = IsNull(ERROR_PROCEDURE(), 'UpdateManagerAndTaskStatusXML')
		exec LocalErrorHandler  @CallingProcName, @CurrentLocation, @LogError = 1, 
								@ErrorNum = @myError output, @message = @message output

		Set @result = @message
	End Catch

 	---------------------------------------------------
	-- Exit
	---------------------------------------------------
Done:
	if @myError = 0
		set @result = @temp
		
	return @myError

GO
GRANT EXECUTE ON [dbo].[UpdateManagerAndTaskStatusXML] TO [DMS_Analysis_Job_Runner] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateManagerAndTaskStatusXML] TO [Limited_Table_Write] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[UpdateManagerAndTaskStatusXML] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateManagerAndTaskStatusXML] TO [PNL\D3M578] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[UpdateManagerAndTaskStatusXML] TO [PNL\D3M580] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateManagerAndTaskStatusXML] TO [PNL\D3M580] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[UpdateManagerAndTaskStatusXML] TO [pnl\D3X050] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateManagerAndTaskStatusXML] TO [pnl\D3X050] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[UpdateManagerAndTaskStatusXML] TO [svc-dms] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateManagerAndTaskStatusXML] TO [svc-dms] AS [dbo]
GO
