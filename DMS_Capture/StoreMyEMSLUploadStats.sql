/****** Object:  StoredProcedure [dbo].[StoreMyEMSLUploadStats] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE dbo.StoreMyEMSLUploadStats
/****************************************************
**
**	Desc: 
**		Store MyEMSL upload stats in T_MyEMSL_Uploads
**	
**	Return values: 0: success, otherwise, error code
**
**	Auth:	mem
**	Date:	03/29/2012 mem - Initial version
**			04/02/2012 mem - Now populating StatusURI_PathID, ContentURI_PathID, and StatusNum
**			04/06/2012 mem - No longer posting a log message if @StatusURI is blank and @FileCountNew=0 and @FileCountUpdated=0
**			08/19/2013 mem - Removed parameter @UpdateURIPathIDsForExistingJob
**			09/06/2013 mem - No longer using @ContentURI
**			09/11/2013 mem - No longer calling PostLogEntry if @StatusURI is invalid but @ErrorCode is non-zero
**    
*****************************************************/
(
    @Job int,
	@DatasetID int,
	@Subfolder varchar(128),
	@FileCountNew int,
	@FileCountUpdated int,
	@Bytes bigint,
	@UploadTimeSeconds real,
	@StatusURI varchar(255),
	@ContentURI varchar(255)='',			-- No longer used (deprecated)
	@ErrorCode int,
	@message varchar(512)='' output,
	@infoOnly tinyint = 0
)
As
	set nocount on
	
	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0

	Declare @EntryID int
	Declare @Dataset varchar(128) = ''

	Declare @CharLoc int
	Declare @SubString varchar(256)
	Declare @LogMsg varchar(512) = ''
	
	Declare @InvalidFormat tinyint

	Declare @StatusURI_PathID int = 1
	Declare @StatusURI_Path varchar(512) = ''
	Declare @StatusNum int = null
		
	---------------------------------------------------
	-- Validate the inputs
	---------------------------------------------------
	
	Set @Job = IsNull(@Job, 0)
	Set @DatasetID = IsNull(@DatasetID, 0)
	Set @Subfolder = IsNull(@Subfolder, '')
	Set @StatusURI = IsNull(@StatusURI, '')
	Set @ContentURI = IsNull(@ContentURI, '')
	
	Set @message = ''
	Set @infoOnly = IsNull(@infoOnly, 0)
	
	---------------------------------------------------
	-- Make sure @Job is defined in T_Jobs
	---------------------------------------------------
	
	IF NOT EXISTS (SELECT * FROM T_Jobs where Job = @Job)
	Begin
		Set @message = 'Job not found in T_Jobs: ' + CONVERT(varchar(12), @Job)
		If @infoOnly <> 0
			Print @message
		return 50000
	End
	
	-----------------------------------------------
	-- Analyze @StatusURI to determine the base URI and the Status Number
	-- For example, in https://a4.my.emsl.pnl.gov/myemsl/cgi-bin/status/644749/xml
	-- extract out     https://a4.my.emsl.pnl.gov/myemsl/cgi-bin/status/
	-- and also        644749
	-----------------------------------------------
	--
	Set @StatusURI_PathID = 1
	Set @StatusURI_Path = ''
	Set @StatusNum = null
	
	If @StatusURI = '' and @FileCountNew = 0 And @FileCountUpdated = 0
	Begin
		-- Nothing to do; leave @StatusURI_PathID as 1
		Set @StatusURI_PathID = 1
	End
	Else
	Begin -- <a1>
		
		-- Setup the log message in case we need it; also, set @InvalidFormat to 1 for now
		Set @LogMsg = 'Unable to extract StatusNum from StatusURI for job ' + Convert(varchar(12), @Job) + ', dataset ' + Convert(varchar(12), @DatasetID)
		Set @InvalidFormat = 1
		
		Set @CharLoc = CharIndex('/status/', @StatusURI)
		If @CharLoc = 0
			Set @LogMsg = @LogMsg + ': /status/ not found in ' + @StatusURI
		Else
		Begin -- <b1>
			-- Extract out the base path, for example:
			-- https://a4.my.emsl.pnl.gov/myemsl/cgi-bin/status/
			Set @StatusURI_Path = SUBSTRING(@StatusURI, 1, @CharLoc + 7)
			
			-- Extract out the text after /status/, for example:
			-- 644749/xml
			Set @SubString = SubString(@StatusURI, @CharLoc + 8, 255)
			
			-- Find the first non-numeric character in @SubString
			set @CharLoc = PATINDEX('%[^0-9]%', @SubString)
			
			If @CharLoc <= 0
			Begin
				If ISNUMERIC(@SubString) <> 0
				Begin
					Set @StatusNum = CONVERT(int, @SubString)			
					Set @InvalidFormat = 0
				End
				Else
				Begin
					Set @LogMsg = @LogMsg + ': number not found after /status/ in ' + @StatusURI
				End
			End
			
			If @CharLoc = 1
			Begin
				Set @LogMsg = @LogMsg + ': number not found after /status/ in ' + @StatusURI
			End
			
			If @CharLoc > 1
			Begin
				Set @StatusNum = CONVERT(int, SUBSTRING(@SubString, 1, @CharLoc-1))
				Set @InvalidFormat = 0
			End
			
		End -- </b1>
		
		If @InvalidFormat <> 0
		Begin
			If @infoOnly = 0
			Begin
				If @ErrorCode = 0
					Exec PostLogEntry 'Error', @LogMsg, 'StoreMyEMSLUploadStats'
			End
			else
				Print @LogMsg
		End
		Else
		Begin -- <b2>
			-- Resolve @StatusURI_Path to @StatusURI_PathID
			
			Exec @StatusURI_PathID = GetURIPathID @StatusURI_Path, @infoOnly=@infoOnly
			
			If @StatusURI_PathID <= 1
			Begin
				Set @LogMsg = 'Unable to resolve StatusURI_Path to URI_PathID for job ' + Convert(varchar(12), @Job) + ', dataset ' + Convert(varchar(12), @DatasetID) + ': ' + @StatusURI_Path
				
				If @infoOnly = 0
					Exec PostLogEntry 'Error', @LogMsg, 'StoreMyEMSLUploadStats'
				Else
					Print @LogMsg
			End
			Else
			Begin
				-- Blank out @StatusURI since we have successfully resolved it into @StatusURI_PathID and @StatusNum
				Set @StatusURI = ''
			End
			
		End -- </b2>
	End -- </a1>
	
	/*
	 *
	-----------------------------------------------
	-- Deprecated code, since @ContentURI will now always be empty
	--
	-- Analyze @ContentURI to determine the base URI, which is the text up to and including /Instrument/Year_Quarter/
	-- For example, in https://a3.my.emsl.pnl.gov/myemsl/query/group/omics.dms.instrument/-later-/group/omics.dms.date_code/-later-/group/omics.dms.dataset/-later-/data/LTQ_Orb_3/2012_1/Athal0501_26Mar12_Jaguar_12-02-27/
	-- extract out     https://a3.my.emsl.pnl.gov/myemsl/query/group/omics.dms.instrument/-later-/group/omics.dms.date_code/-later-/group/omics.dms.dataset/-later-/data/LTQ_Orb_3/2012_1/
	-----------------------------------------------
	--
	Declare @ContentURI_PathID int = 1
	Declare @ContentURI_Path varchar(512) = ''
	
	If @ContentURI = '' and @FileCountNew = 0 And @FileCountUpdated = 0
	Begin
		-- Nothing to do; leave@ContentURI_PathID as 1
		Set @ContentURI_PathID = 1
	End
	Else
	Begin -- <a2>
		
		-- Setup the log message in case we need it; also, set @InvalidFormat to 1 for now
		Set @LogMsg = 'Unable to extract expected text from ContentURI for job ' + Convert(varchar(12), @Job) + ', dataset ' + Convert(varchar(12), @DatasetID)
		Set @InvalidFormat = 1
		
		Set @CharLoc = CharIndex('/data/', @ContentURI)
		If @CharLoc = 0
			Set @LogMsg = @LogMsg + ': /data/ not found in ' + @ContentURI
		Else
		Begin -- <b3>
			-- Extract out the base path, for example:
			-- https://a3.my.emsl.pnl.gov/myemsl/query/group/omics.dms.instrument/-later-/group/omics.dms.date_code/-later-/group/omics.dms.dataset/-later-/data/
			Set @ContentURI_Path = SUBSTRING(@ContentURI, 1, @CharLoc + 5)
			
			-- Extract out the text after /data/, for example:
			-- LTQ_Orb_3/2012_1/Athal0501_26Mar12_Jaguar_12-02-27/
			Set @SubString = SubString(@ContentURI, @CharLoc + 6, 255)
			
			-- Remove Instrument Name and Year_Quarter from @SubString and append to @ContentURI_Path
			-- Do this by looking for the Year_Quarter folder, e.g. /2012_1/
			set @CharLoc = PATINDEX('%/[2-9][0-9][0-9][0-9][_][0-9]/%', @SubString)

			If @CharLoc <= 0
			Begin -- <c1>
				-- Match not found; look for the dataset name instead
				
				SELECT @Dataset = Dataset
				FROM T_Jobs
				WHERE Job = @Job
				--
				SELECT @myError = @@error, @myRowCount = @@rowcount
				
				If @myRowCount = 0
				Begin
					-- Job not found; log an error
					Set @LogMsg = @LogMsg + ': Year_Quarter not found in the URI and Job not found in T_Jobs; ' + @ContentURI				
				End
				Else
				Begin -- <d1>
					-- Look for @Dataset in @SubString
					Set @CharLoc = CharIndex(@Dataset, @SubString)
					
					If @CharLoc > 1
					Begin
						Set @ContentURI_Path = @ContentURI_Path + Substring(@SubString, 1, @CharLoc-1)
						Set @SubString = SubString(@SubString, @CharLoc, 255)					
						Set @InvalidFormat = 0
					End
					Else
					Begin
						Set @LogMsg = @LogMsg + ': Year_Quarter not found in the URI; dataset name also not found; ' + @ContentURI		
					End				
				End -- </d1>			
				
			End -- </c1>
			Else
			Begin
				Set @ContentURI_Path = @ContentURI_Path + Substring(@SubString, 1, @CharLoc+7)
				Set @SubString = SubString(@SubString, @CharLoc+8, 255)					
				Set @InvalidFormat = 0			
			End
					
		End -- </b3>
		
		If @InvalidFormat <> 0
		Begin
			If @infoOnly = 0
				Exec PostLogEntry 'Error', @LogMsg, 'StoreMyEMSLUploadStats'
			else
				Print @LogMsg
		End
		Else
		Begin -- <b4>
			-- Resolve @ContentURI_Path to @ContentURI_PathID
			
			Exec @ContentURI_PathID = GetURIPathID @ContentURI_Path, @infoOnly=@infoOnly
			
			If @ContentURI_PathID <= 1
			Begin
				Set @LogMsg = 'Unable to resolve ContentURI_Path to URI_PathID for job ' + Convert(varchar(12), @Job) + ', dataset ' + Convert(varchar(12), @DatasetID) + ': ' + @ContentURI_Path
				
				If @infoOnly = 0
					Exec PostLogEntry 'Error', @LogMsg, 'StoreMyEMSLUploadStats'
				Else
					Print @LogMsg
			End		
			Begin
				-- Blank out @ContentURI since we have successfully resolved it into @ContentURI_PathID
				Set @ContentURI = ''
			End

		End -- </b4>
	End -- </a2>
	*/	
	
	If @infoOnly <> 0
	Begin
		-----------------------------------------------
		-- Preview the data, then exit
		-----------------------------------------------
		
		SELECT @Job AS Job,
		       @DatasetID AS Dataset_ID,
		       @Subfolder AS Subfolder,
		       @FileCountNew AS FileCountNew,
		       @FileCountUpdated AS FileCountUpdated,
		       @Bytes / 1024.0 / 1024.0 AS MB_Transferred,
		       @UploadTimeSeconds AS UploadTimeSeconds,
		       @StatusURI AS URI,
		       @StatusURI_PathID AS StatusURI_PathID,
		       @StatusNum as StatusNum,	
		       @ErrorCode AS ErrorCode
		       
		
	End
	Else
	Begin -- <a3>
		
		-----------------------------------------------
		-- Add a new row to T_MyEmsl_Uploads
		-----------------------------------------------
		--
		INSERT INTO T_MyEmsl_Uploads( Job,
			                            Dataset_ID,
			                            Subfolder,
			                            FileCountNew,
			                            FileCountUpdated,
			                            Bytes,
			                            UploadTimeSeconds,
			                            StatusURI_PathID,
			                            StatusNum,
			                            ErrorCode,
			                            Entered )
		SELECT @Job,
			    @DatasetID,
			    @Subfolder,
			    @FileCountNew,
			    @FileCountUpdated,
			    @Bytes,
			    @UploadTimeSeconds,
			    @StatusURI_PathID,
			    @StatusNum,
			    @ErrorCode,
			    GetDate()
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
		begin
			set @message = 'Error adding new row to T_MyEmsl_Uploads for job ' + Convert(varchar(12), @job)
		end	
		

		
	End -- </a3>
	
Done:

	If @myError <> 0
	Begin
		If @message = ''
			Set @message = 'Error in StoreMyEMSLUploadStats'
		
		Set @message = @message + '; error code = ' + Convert(varchar(12), @myError)
		
		If @InfoOnly = 0
			Exec PostLogEntry 'Error', @message, 'StoreMyEMSLUploadStats'
	End
	
	If Len(@message) > 0 AND @InfoOnly <> 0
		Print @message

	Return @myError

GO
GRANT EXECUTE ON [dbo].[StoreMyEMSLUploadStats] TO [svc-dms] AS [dbo]
GO
