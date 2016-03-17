/****** Object:  StoredProcedure [dbo].[GetInstrumentStoragePathForNewDatasets] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE GetInstrumentStoragePathForNewDatasets
/****************************************************
**
**	Desc:	Returns the ID for the most appropriate storage path for 
**			new data uploaded for the given instrument.
**
**			If the Instrument has Auto_Define_Storage_Path enabled in
**			T_Instrument_Name, then will auto-define the storage path 
**			based on the current year and quarter
**
**			If necessary, will call AddUpdateStorage to auto-create an entry in T_Storage_Path
**
**	Returns: The storage path ID; 0 if an error
**
**	Auth:	mem
**	Date:	05/11/2011 mem - Initial Version
**			05/12/2011 mem - Added @RefDate and @AutoSwitchActiveStorage
**			02/23/2016 mem - Add set XACT_ABORT on
**    
*****************************************************/
(
	@InstrumentID int,
	@RefDate datetime = null,
	@AutoSwitchActiveStorage tinyint = 1,
	@infoOnly tinyint = 0
)
AS
	Set XACT_ABORT, nocount on

	Declare @myRowCount int	
	Declare @myError int
	Set @myRowCount = 0
	Set @myError = 0
	
	Declare @StoragePathID int
	Declare @message varchar(255)
	
	Declare @AutoDefineStoragePath tinyint
	
	Declare @AutoSPVolNameClient varchar(128)
	Declare @AutoSPVolNameServer varchar(128)
	Declare @AutoSPPathRoot varchar(128)

	Declare @InstrumentName varchar(64)
	
	Declare @CallingProcName varchar(128)
	Declare @CurrentLocation varchar(128)
	Set @CurrentLocation = 'Start'

	Begin try

		-----------------------------------------
		-- See if this instrument has Auto_Define_Storage_Path enabled
		-----------------------------------------
		--
		Set @AutoDefineStoragePath = 0
		Set @StoragePathID = 0
		
		SELECT  @AutoDefineStoragePath = Auto_Define_Storage_Path,
				@AutoSPVolNameClient = Auto_SP_Vol_Name_Client,
				@AutoSPVolNameServer = Auto_SP_Vol_Name_Server,
				@AutoSPPathRoot = Auto_SP_Path_Root,
				@InstrumentName = IN_Name
		FROM T_Instrument_Name
		WHERE Instrument_ID = @InstrumentID
		--
		SELECT @myRowCount = @@rowcount, @myError = @@error

		If IsNull(@AutoDefineStoragePath, 0) = 0
		Begin
			-- Using the storage path defined in T_Instrument_Name
			
			SELECT @StoragePathID = IN_storage_path_ID
			FROM T_Instrument_Name
			WHERE Instrument_ID = @instrumentID
			--
			SELECT @myRowCount = @@rowcount, @myError = @@error
		End
		Else
		Begin -- <a>
		
			Declare @CurrentYear int
			Declare @CurrentQuarter tinyint
			Declare @StoragePathName varchar(255)
			
			Set @CurrentLocation = 'Auto-defining storage path'
			
			-- Validate the @AutoSP variables
			If IsNull(@AutoSPVolNameClient, '') = '' OR
			   IsNull(@AutoSPVolNameServer, '') = '' OR
			   IsNull(@AutoSPPathRoot, '') = ''		   
			Begin
				Set @message = 'One or more Auto_SP fields are empty or null for instrument ' + @InstrumentName + '; unable to auto-define the storage path'
				
				If @infoOnly = 0
					exec PostLogEntry 'Error', @message, 'GetInstrumentStoragePathForNewDatasets'
				Else
					print @message
			End
			Else
			Begin -- <b>
				-----------------------------------------
				-- Define the StoragePath
				-- It will look like VOrbiETD01\2011_2\
				-----------------------------------------

				Set @RefDate = IsNull(@RefDate, GetDate())
					
				SELECT @CurrentYear = DatePart(year, @RefDate),
					   @CurrentQuarter = DatePart(quarter, @RefDate)
				
				Declare @Suffix varchar(128)
				Set @Suffix = Convert(varchar(8), @CurrentYear) + '_' + Convert(varchar(4), @CurrentQuarter) + '\'
				
				Set @StoragePathName = @AutoSPPathRoot
				
				If Right(@StoragePathName, 1) <> '\'
						Set @StoragePathName = @StoragePathName + '\'
						
				Set @StoragePathName = @StoragePathName + @Suffix
								
				-----------------------------------------
				-- Look for existing entry in T_Storage_Path
				-----------------------------------------
				
				SELECT @StoragePathID = SP_path_ID
				FROM T_Storage_Path
				WHERE SP_Path = @StoragePathName AND
					  SP_Vol_Name_Client = @AutoSPVolNameClient AND
					  SP_Vol_Name_Server = @AutoSPVolNameServer AND
					  (SP_Function = 'raw-storage' OR 
					   SP_Function = 'old-storage' AND @AutoSwitchActiveStorage = 0)
				--
				SELECT @myRowCount = @@rowcount, @myError = @@error
				
				If @myRowCount = 0
				Begin
					-- Path not found; add it if @infoOnly <> 0
					If @infoOnly <> 0
						Print 'Auto-defined storage path "' + @StoragePathName + '" not found T_Storage_Path; need to add it'
					Else
					Begin
						Set @CurrentLocation = 'Call AddUpdateStorage to add ' + @StoragePathName
						
						Declare @StorageFunction varchar(24)
						
						If @AutoSwitchActiveStorage = 0
							Set @StorageFunction = 'old-storage'
						Else
							Set @StorageFunction = 'raw-storage'

						Exec AddUpdateStorage @StoragePathName, 
						                      @AutoSPVolNameClient,
						                      @AutoSPVolNameServer, 
						                      @storFunction=@StorageFunction, 
						                      @instrumentName=@InstrumentName, 
						                      @description='', 
						                      @ID=@StoragePathID output, 
						                      @mode='add',
						                      @message=@message output

					End

				End
				Else
				Begin
					If @infoOnly <> 0
						Print 'Auto-defined storage path "' + @StoragePathName + '" matched in T_Storage_Path; ID=' + Convert(varchar(12), @StoragePathID)
				End
				
			End -- </b>
					
		End -- </a>
							
	End Try
	Begin Catch					
		-- Error caught; log the error and set @StoragePathID to 0
		
		Set @CallingProcName = IsNull(ERROR_PROCEDURE(), 'GetInstrumentStoragePathForNewDatasets')
		exec LocalErrorHandler  @CallingProcName, @CurrentLocation, @LogError = 1, 
							@ErrorNum = @myError output, @message = @message output
		
	End catch
		
	-----------------------------------------
	-- Return the storage path ID
	-----------------------------------------
	--
	Set @StoragePathID = IsNull(@StoragePathID, 0)

	return @StoragePathID

GO
GRANT VIEW DEFINITION ON [dbo].[GetInstrumentStoragePathForNewDatasets] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[GetInstrumentStoragePathForNewDatasets] TO [PNL\D3M580] AS [dbo]
GO
