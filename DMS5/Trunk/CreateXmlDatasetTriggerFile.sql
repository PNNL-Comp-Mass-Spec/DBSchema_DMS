/****** Object:  StoredProcedure [dbo].[CreateXmlDatasetTriggerFile] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure [dbo].[CreateXmlDatasetTriggerFile]
/****************************************************
**		File: 
**		Name: CreateXmlDatasetTriggerFile
**		Desc: Creates an XML dataset trigger file to deposit into a directory
**			where the DIM will pick it up, validate the dataset file(s) are available,
**			and submit back to DMS
**
**		Return values: 0: success, otherwise, error code
** 
**		Parameters:
**
**		Auth: jds
**		Date: 10/03/2007
**		04/26/2010 grk - widened @Dataset_Name to 128 characters
**    
*****************************************************/
	@Dataset_Name		varchar(128),  -- @datasetNum
	@Experiment_Name	varchar(64),  -- @experimentNum
	@Instrument_Name	varchar(64),  -- @instrumentName
	@Separation_Type	varchar(64),  -- @secSep
	@LC_Cart_Name		varchar(128), -- @LCCartName
	@LC_Column			varchar(64),  -- @LCColumnNum
	@Wellplate_Number	varchar(64),  -- @wellplateNum
	@Well_Number		varchar(64),  -- @wellNum
	@Dataset_Type		varchar(20),  -- @msType
	@Operator_PRN		varchar(64),  -- @operPRN
	@DSCreator_PRN		varchar(64),  -- @DScreatorPRN
	@Comment			varchar(512), -- @comment
	@Interest_Rating	varchar(32),  -- @rating
	@Request			int,          -- @requestID
	@EMSL_Usage_Type	varchar(50) = '',  -- @eusUsageType
	@EMSL_Proposal_ID	varchar(10) = '',  -- @eusProposalID
	@EMSL_Users_List	varchar(1024) = '', -- @eusUsersList
	@Run_Start		    varchar(64),
	@Run_Finish		    varchar(64),
	@message varchar(512) output
As
set nocount on

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	
	declare @filePath varchar(100)
	select @filePath = server
	from T_MiscPaths
	where [Function] = 'DIMTriggerFileDir'

	declare @filename varchar(150)
	set @filename = @filePath + 'man_' + @Dataset_Name + '.xml'

	declare @xmlLine varchar(50)
	set @xmlLine = ''

	set @message = ''

	---------------------------------------------------
	-- create XML dataset trigger file lines
	---------------------------------------------------
	declare @tmpXmlLine varchar(4000)
	DECLARE @result int

	--XML Header
	set @tmpXmlLine = '<?xml version="1.0" ?>' + char(13) + char(10)
	set @tmpXmlLine = @tmpXmlLine + '<Dataset>' + char(13) + char(10)
	--Dataset Name
	set @tmpXmlLine = @tmpXmlLine + '<Parameter Name="Dataset Name" Value="' + @Dataset_Name + '"/>' + char(13) + char(10)
	--Experiment Name
	set @tmpXmlLine = @tmpXmlLine + '<Parameter Name="Experiment Name" Value="' + @Experiment_Name + '"/>' + char(13) + char(10)
	--Instrument Name
	set @tmpXmlLine = @tmpXmlLine + '<Parameter Name="Instrument Name" Value="' + @Instrument_Name + '"/>' + char(13) + char(10)
	--Separation Type
	set @tmpXmlLine = @tmpXmlLine + '<Parameter Name="Separation Type" Value="' + @Separation_Type + '"/>' + char(13) + char(10)
	--LC Cart Name
	set @tmpXmlLine = @tmpXmlLine + '<Parameter Name="LC Cart Name" Value="' + @LC_Cart_Name + '"/>' + char(13) + char(10)
	--LC Column
	set @tmpXmlLine = @tmpXmlLine + '<Parameter Name="LC Column" Value="' + @LC_Column + '"/>' + char(13) + char(10)
	--Wellplate Number
	set @tmpXmlLine = @tmpXmlLine + '<Parameter Name="Wellplate Number" Value="' + @Wellplate_Number + '"/>' + char(13) + char(10)
	--Well Number
	set @tmpXmlLine = @tmpXmlLine + '<Parameter Name="Well Number" Value="' + @Well_Number + '"/>' + char(13) + char(10)
	--Dataset Type
	set @tmpXmlLine = @tmpXmlLine + '<Parameter Name="Dataset Type" Value="' + @Dataset_Type + '"/>' + char(13) + char(10)
	--Operator (PRN)
	set @tmpXmlLine = @tmpXmlLine + '<Parameter Name="Operator (PRN)" Value="' + @Operator_PRN + '"/>' + char(13) + char(10)
	--Dataset Creator (PRN)
	set @tmpXmlLine = @tmpXmlLine + '<Parameter Name="DS Creator (PRN)" Value="' + @DSCreator_PRN + '"/>' + char(13) + char(10)
	--Comment
	set @tmpXmlLine = @tmpXmlLine + '<Parameter Name="Comment" Value="' + @Comment + '"/>' + char(13) + char(10)
	--Interest Rating
	set @tmpXmlLine = @tmpXmlLine + '<Parameter Name="Interest Rating" Value="' + @Interest_Rating + '"/>' + char(13) + char(10)
	--Request
	set @tmpXmlLine = @tmpXmlLine + '<Parameter Name="Request" Value="' + cast(@Request as varchar(32)) + '"/>' + char(13) + char(10)
	--EMSL Proposal ID
	set @tmpXmlLine = @tmpXmlLine + '<Parameter Name="EMSL Proposal ID" Value="' + isnull(@EMSL_Proposal_ID, '') + '"/>' + char(13) + char(10)
	--EMSL Usage Type
	set @tmpXmlLine = @tmpXmlLine + '<Parameter Name="EMSL Usage Type" Value="' + @EMSL_Usage_Type + '"/>' + char(13) + char(10)
	--EMSL Users List
	set @tmpXmlLine = @tmpXmlLine + '<Parameter Name="EMSL Users List" Value="' + @EMSL_Users_List + '"/>' + char(13) + char(10)
	--Run Start
	set @tmpXmlLine = @tmpXmlLine + '<Parameter Name="Run Start" Value="' + @Run_Start + '"/>' + char(13) + char(10)
	--Run Finish
	set @tmpXmlLine = @tmpXmlLine + '<Parameter Name="Run Finish" Value="' + @Run_Finish + '"/>' + char(13) + char(10)
	--Close XML file
	set @tmpXmlLine = @tmpXmlLine + '</Dataset>' + char(13) + char(10)

	---------------------------------------------------
	-- write XML dataset trigger file
	---------------------------------------------------
	DECLARE @fso int
	DECLARE @hr int
	DECLARE @ts int
	DECLARE @property varchar(255)
	DECLARE @return varchar(255)
	DECLARE @src varchar(255), @desc varchar(255)

	-- Create a filesystem object
	EXEC @hr = sp_OACreate 'Scripting.FileSystemObject', @fso OUT
	IF @hr <> 0
	BEGIN
		EXEC sp_OAGetErrorInfo @fso, @src OUT, @desc OUT
		SELECT hr=convert(varbinary(4),@hr), Source=@src, Description=@desc
	    goto Done
	END

	-- see if file already exists
	--
	EXEC @hr = sp_OAMethod  @fso, 'FileExists', @result OUT, @FileName
	IF @hr <> 0
	BEGIN
	    EXEC LoadGetOAErrorMessage @fso, @hr, @message OUT
		set @myError = 60
	    goto DestroyFSO
	END

	If @result = 1
	begin
		set @message = 'Trigger file already exists.  Enter a different dataset name'
		set @myError = 62
	    goto DestroyFSO
	end

	-- Open the text file for appending (1- ForReading, 2 - ForWriting, 8 - ForAppending)
	EXEC @hr = sp_OAMethod @fso, 'OpenTextFile', @ts OUT, @FileName, 8, true
	IF @hr <> 0
	BEGIN
		EXEC sp_OAGetErrorInfo @fso, @src OUT, @desc OUT
		SELECT hr=convert(varbinary(4),@hr), Source=@src, Description=@desc
		set @myError = 64
	    goto DestroyFSO
	END

	-- call the write method of the text stream to write the trigger file
	EXEC @hr = sp_OAMethod @ts, 'WriteLine', NULL, @tmpXmlLine
	IF @hr <> 0
	BEGIN
		EXEC sp_OAGetErrorInfo @fso, @src OUT, @desc OUT
		SELECT hr=convert(varbinary(4),@hr), Source=@src, Description=@desc
		set @myError = 66
	    goto DestroyFSO
	END

	-- Close the text stream
	EXEC @hr = sp_OAMethod @ts, 'Close', NULL
	IF @hr <> 0
	BEGIN
		EXEC sp_OAGetErrorInfo @fso, @src OUT, @desc OUT
		SELECT hr=convert(varbinary(4),@hr), Source=@src, Description=@desc
		set @myError = 68
	    goto DestroyFSO
	END


	return 0

	-----------------------------------------------
	-- clean up file system object
	-----------------------------------------------
  
DestroyFSO:
	-- Destroy the FileSystemObject object.
	--
	EXEC @hr = sp_OADestroy @fso
	IF @hr <> 0
	BEGIN
	    EXEC LoadGetOAErrorMessage @fso, @hr, @message OUT
		set @myError = 60
		goto done
	END

	-----------------------------------------------
	-- Exit
	-----------------------------------------------
Done:
	
	return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[CreateXmlDatasetTriggerFile] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[CreateXmlDatasetTriggerFile] TO [PNL\D3M580] AS [dbo]
GO
