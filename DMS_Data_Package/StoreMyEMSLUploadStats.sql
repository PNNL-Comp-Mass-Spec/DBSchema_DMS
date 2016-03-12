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
**	Date:	09/25/2013 mem - Initial version
**    
*****************************************************/
(
	@DataPackageID int,
	@Subfolder varchar(128),
	@FileCountNew int,
	@FileCountUpdated int,
	@Bytes bigint,
	@UploadTimeSeconds real,
	@StatusURI varchar(255),
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
	
	Set @DataPackageID = IsNull(@DataPackageID, 0)
	Set @Subfolder = IsNull(@Subfolder, '')
	Set @StatusURI = IsNull(@StatusURI, '')
	
	Set @message = ''
	Set @infoOnly = IsNull(@infoOnly, 0)
	
	---------------------------------------------------
	-- Make sure @DataPackageID is defined in T_Data_Package
	---------------------------------------------------
	
	IF NOT EXISTS (SELECT * FROM T_Data_Package	WHERE ID = @DataPackageID)
	Begin
		Set @message = 'Data Package ID not found in T_Data_Package: ' + CONVERT(varchar(12), @DataPackageID)
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
		Set @LogMsg = 'Unable to extract StatusNum from StatusURI for Data Package ' + Convert(varchar(12), @DataPackageID)
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
				Set @LogMsg = 'Unable to resolve StatusURI_Path to URI_PathID for Data Package ' + Convert(varchar(12), @DataPackageID) + ': ' + @StatusURI_Path
				
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
	
	If @infoOnly <> 0
	Begin
		-----------------------------------------------
		-- Preview the data, then exit
		-----------------------------------------------
		
		SELECT @DataPackageID AS DataPackageID,
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
		INSERT INTO T_MyEmsl_Uploads(   Data_Package_ID,
			                            Subfolder,
			                            FileCountNew,
			                            FileCountUpdated,
			                            Bytes,
			                            UploadTimeSeconds,
			                            StatusURI_PathID,
			                            StatusNum,
			                            ErrorCode,
			                            Entered )
		SELECT  @DataPackageID,
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
			set @message = 'Error adding new row to T_MyEmsl_Uploads for Data Package ' + Convert(varchar(12), @DataPackageID)
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
GRANT EXECUTE ON [dbo].[StoreMyEMSLUploadStats] TO [DMS_SP_User] AS [dbo]
GO
