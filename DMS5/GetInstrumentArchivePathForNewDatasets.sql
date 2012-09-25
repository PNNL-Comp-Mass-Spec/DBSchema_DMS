/****** Object:  StoredProcedure [dbo].[GetInstrumentArchivePathForNewDatasets] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE GetInstrumentArchivePathForNewDatasets
/****************************************************
**
**	Desc:	Returns the ID for the most appropriate archive path for 
**			the initial archive of new datasets uploaded for the given instrument
**
**			If the Instrument has Auto_Define_Storage_Path enabled in
**			T_Instrument_Name, then will auto-define the archive path 
**			based on the current year and quarter 
**
**			If @DatasetID is defined, then uses the DS_Created value of the given dataset
**			rather than the current date
**
**			If necessary, will call AddUpdateArchivePath to auto-create an entry in T_Archive_Path
**			Optionally set @AutoSwitchActiveArchive to 0 to not auto-update the system to use the 
**			archive path determined for future datasets for this instrument
**
**	Returns: The archive path ID; 0 if an error
**
**	Auth:	mem
**	Date:	05/11/2011 mem - Initial Version
**			05/12/2011 mem - Added @DatasetID and @AutoSwitchActiveArchive
**			05/16/2011 mem - Now filtering T_Archive_Path using only AP_Function IN ('Active', 'Old') when auto-defining the archive path
**    
*****************************************************/
(
	@InstrumentID int,
	@DatasetID int = null,
	@AutoSwitchActiveArchive tinyint = 1,
	@infoOnly tinyint = 0
)
AS
	Set NoCount On

	Declare @myRowCount int	
	Declare @myError int
	Set @myRowCount = 0
	Set @myError = 0
	
	Declare @ArchivePathID int
	Declare @message varchar(255)
	
	Declare @AutoDefineStoragePath tinyint

	Declare @AutoSPArchiveServerName varchar(64)
	Declare @AutoSPArchivePathRoot varchar(128)
	Declare @AutoSPArchiveSharePathRoot varchar(128)

	Declare @InstrumentName varchar(64)
	
	Declare @CallingProcName varchar(128)
	Declare @CurrentLocation varchar(128)
	Set @CurrentLocation = 'Start'

	Begin Try

		-----------------------------------------
		-- See if this instrument has Auto_Define_Storage_Path enabled
		-----------------------------------------
		--
		Set @AutoDefineStoragePath = 0
		Set @ArchivePathID = 0
		
		SELECT  @AutoDefineStoragePath = Auto_Define_Storage_Path,
				@AutoSPArchiveServerName = Auto_SP_Archive_Server_Name, 
				@AutoSPArchivePathRoot = Auto_SP_Archive_Path_Root, 
				@AutoSPArchiveSharePathRoot = Auto_SP_Archive_Share_Path_Root,
				@InstrumentName = IN_Name
		FROM T_Instrument_Name
		WHERE Instrument_ID = @InstrumentID
		--
		SELECT @myRowCount = @@rowcount, @myError = @@error

		If IsNull(@AutoDefineStoragePath, 0) = 0
		Begin
			-- Using the archive path defined in T_Archive_Path for @InstrumentID

			SELECT @ArchivePathID = AP_path_ID
			FROM T_Archive_Path
			WHERE (AP_Function = 'Active') AND
				  (AP_instrument_name_ID = @InstrumentID)
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			
		End
		Else
		Begin -- <a>
		
			Declare @CurrentYear int
			Declare @CurrentQuarter tinyint
			Declare @ArchivePathName varchar(255)
			
			Set @CurrentLocation = 'Auto-defining archive path'

			-- Validate the @AutoSP variables
			If IsNull(@AutoSPArchiveServerName, '') = '' OR
			   IsNull(@AutoSPArchivePathRoot, '') = '' OR
			   IsNull(@AutoSPArchiveSharePathRoot, '') = ''		   
			Begin
				Set @message = 'One or more Auto_SP fields are empty or null for instrument ' + @InstrumentName + '; unable to auto-define the archive path'
				
				If @infoOnly = 0
					exec PostLogEntry 'Error', @message, 'GetInstrumentArchivePathForNewDatasets'
				Else
					print @message
			End
			Else
			Begin -- <b>
				-----------------------------------------
				-- Define the ArchivePath and NetworkSharePath
				-- Archive path will look like /archive/dmsarch/VOrbiETD02/2011_2
				-- NetworkSharePath will look like \\a2.emsl.pnl.gov\dmsarch\VOrbiETD02\2011_2
				-----------------------------------------
				Declare @RefDate datetime
				
				If IsNull(@DatasetID, 0) > 0
					SELECT @RefDate = IsNull(DS_Created, GetDate())
					FROM T_Dataset
					WHERE Dataset_ID = @DatasetID
				Else
					Set @RefDate = GetDate()

				SELECT @CurrentYear = DatePart(year, @RefDate),
				       @CurrentQuarter = DatePart(quarter, @RefDate)

				
				Declare @Suffix varchar(128)
				Declare @NetworkSharePath varchar(128)			
				Set @Suffix = Convert(varchar(8), @CurrentYear) + '_' + Convert(varchar(4), @CurrentQuarter)
				
				Set @ArchivePathName = @AutoSPArchivePathRoot
				
				If Right(@ArchivePathName, 1) <> '/'
						Set @ArchivePathName = @ArchivePathName + '/'

				Set @ArchivePathName = @ArchivePathName + @Suffix
				
				Set @NetworkSharePath = @AutoSPArchiveSharePathRoot 
				If Right(@NetworkSharePath, 1) <> '\'
						Set @NetworkSharePath = @NetworkSharePath + '\'
						
				Set @NetworkSharePath = @NetworkSharePath + @Suffix
				
				-----------------------------------------
				-- Look for existing entry in T_Archive_Path
				-- Limit to Active entries only if @AutoSwitchActiveArchive is non-zero
				-----------------------------------------
				
				SELECT @ArchivePathID = AP_path_ID
				FROM T_Archive_Path
				WHERE AP_Archive_Path = @ArchivePathName AND
					  AP_Function IN ('Active', 'Old')
				--
				SELECT @myRowCount = @@rowcount, @myError = @@error
				
				If @myRowCount = 0
				Begin
					-- Path not found; add it if @infoOnly <> 0
					If @infoOnly <> 0
						Print 'Auto-defined archive path "' + @ArchivePathName + '" not found T_Archive_Path; need to add it'
					Else
					Begin
						Set @CurrentLocation = 'Call AddUpdateArchivePath to add ' + @ArchivePathName
						
						Declare @ArchiveFunction varchar(24)
						
						If @AutoSwitchActiveArchive = 0
							Set @ArchiveFunction = 'Old'
						Else
							Set @ArchiveFunction = 'Active'

						Exec AddUpdateArchivePath @ArchivePathID output, 
						                          @ArchivePathName, 
						                          @AutoSPArchiveServerName, 
						                          @InstrumentName, 
						                          @NetworkSharePath, 
						                          @ArchiveNote=@InstrumentName,
						                          @ArchiveFunction=@ArchiveFunction, 
						                          @mode='add', 
						                          @message=@message output

					End

				End
				Else
				Begin
					If @infoOnly <> 0
						Print 'Auto-defined archive path "' + @ArchivePathName + '" matched in T_Archive_Path; ID=' + Convert(varchar(12), @ArchivePathID)
				End
				
			End -- </b>
					
		End -- </a>
							
	End Try
	Begin Catch					
		-- Error caught; log the error and set @ArchivePathID to 0
		
		Set @CallingProcName = IsNull(ERROR_PROCEDURE(), 'GetInstrumentArchivePathForNewDatasets')
		exec LocalErrorHandler  @CallingProcName, @CurrentLocation, @LogError = 1, 
							@ErrorNum = @myError output, @message = @message output
		
	End Catch
		
	-----------------------------------------
	-- Return the archive path ID
	-----------------------------------------
	--
	Set @ArchivePathID = IsNull(@ArchivePathID, 0)

	return @ArchivePathID

GO
GRANT VIEW DEFINITION ON [dbo].[GetInstrumentArchivePathForNewDatasets] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[GetInstrumentArchivePathForNewDatasets] TO [PNL\D3M580] AS [dbo]
GO
