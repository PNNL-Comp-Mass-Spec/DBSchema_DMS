/****** Object:  StoredProcedure [dbo].[ValidateInstrumentAndDatasetType] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure dbo.ValidateInstrumentAndDatasetType
/****************************************************
**
**	Desc:
**   
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**	Auth:	grk
**	Date:	09/04/2007 (Ticket 512 http://prismtrac.pnl.gov/trac/ticket/512)
**			09/16/2009 mem - Now checking dataset type (@DatasetType) against T_Instrument_Allowed_Dataset_Type (Ticket #748)
**
*****************************************************/
(
	@DatasetType varchar(20),
	@instrumentName varchar(64),
	@instrumentID int output,
	@datasetTypeID int output,
	@message varchar(512) output
)
As
	set nocount on

	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0

	set @message = ''

	---------------------------------------------------
	-- verify that dataset type is valid 
	-- and get its id number
	---------------------------------------------------
	set @datasetTypeID = 0
	execute @datasetTypeID = GetDatasetTypeID @DatasetType
	if @datasetTypeID = 0
	begin
		set @message = 'Could not find entry in database for dataset type "' + @DatasetType + '"'
		print @message
		return 51118
	end

	declare @storagePathID int
	set @storagePathID = 0

	---------------------------------------------------
	-- Resolve instrument ID
	---------------------------------------------------
	declare @InstrumentMatch varchar(64)

	set @instrumentID = 0
	execute @instrumentID = GetinstrumentID @instrumentName
	
	if @instrumentID = 0
	begin
		-- Could not resolve the instrument name
		-- This is OK for requests, since the precise instrument need not be specified
		-- We'll try to guess the correct instrument class given the name specified by the user,
		--  but if we can't guess it, then we won't be able to validate the requested dataset type
		
		If @instrumentID = 0 AND @instrumentName LIKE 'LCQ%'
		Begin
			SELECT TOP 1 @instrumentID = Instrument_ID, @InstrumentMatch = IN_Name
			FROM dbo.T_Instrument_Name
			WHERE (IN_name LIKE 'LCQ%')
			ORDER BY IN_Name
		End
		
		If @instrumentID = 0 AND (@instrumentName = 'LTQ' OR @instrumentName Like 'LTQ_[0-9]')
		Begin
			SELECT TOP 1 @instrumentID = Instrument_ID, @InstrumentMatch = IN_Name
			FROM dbo.T_Instrument_Name
			WHERE (IN_name LIKE 'LTQ%')
			ORDER BY IN_Name
		End
		
		If @instrumentID = 0 AND @instrumentName LIKE 'LTQ_FT%'
		Begin
			SELECT TOP 1 @instrumentID = Instrument_ID, @InstrumentMatch = IN_Name
			FROM dbo.T_Instrument_Name
			WHERE (IN_name LIKE 'LTQ_FT%')
			ORDER BY IN_Name
		End

		If @instrumentID = 0 AND @instrumentName LIKE 'LTQ_Orb%'
		Begin
			SELECT TOP 1 @instrumentID = Instrument_ID, @InstrumentMatch = IN_Name
			FROM dbo.T_Instrument_Name
			WHERE (IN_name LIKE 'LTQ_Orb%')
			ORDER BY IN_Name
		End

		If @instrumentID = 0 AND @instrumentName LIKE 'Exact%'
		Begin
			SELECT TOP 1 @instrumentID = Instrument_ID, @InstrumentMatch = IN_Name
			FROM dbo.T_Instrument_Name
			WHERE (IN_name LIKE 'Exact%')
			ORDER BY IN_Name
		End

		If @instrumentID = 0 AND @instrumentName LIKE 'VOrbi%'
		Begin
			SELECT TOP 1 @instrumentID = Instrument_ID, @InstrumentMatch = IN_Name
			FROM dbo.T_Instrument_Name
			WHERE (IN_name LIKE 'VOrbi%')
			ORDER BY IN_Name
		End

		If @instrumentID = 0 AND @instrumentName LIKE 'Agilent_TOF%'
		Begin
			SELECT TOP 1 @instrumentID = Instrument_ID, @InstrumentMatch = IN_Name
			FROM dbo.T_Instrument_Name
			WHERE (IN_name LIKE 'Agilent_TOF%')
			ORDER BY IN_Name
		End

		If @instrumentID = 0 AND @instrumentName LIKE '%T_FTICR%'
		Begin
			SELECT TOP 1 @instrumentID = Instrument_ID, @InstrumentMatch = IN_Name
			FROM dbo.T_Instrument_Name
			WHERE (IN_name LIKE @instrumentName + '%')
			ORDER BY IN_Name
		End

		If @instrumentID = 0
		Begin
			Set @message = 'Instrument "' + @instrumentName + '" was not recognized and therefore the dataset type (' + @DatasetType + ') could not be validated'
			goto Done
		End
		
	end

	---------------------------------------------------
	-- Verify that dataset type is valid for given instrument
	---------------------------------------------------

	declare @allowedDatasetTypes varchar(255)
	declare @MatchCount int
	
	If @instrumentID <> 0
	Begin

		If Not Exists (SELECT * FROM T_Instrument_Allowed_Dataset_Type WHERE Instrument = @instrumentName AND Dataset_Type = @DatasetType)
		begin
			Set @allowedDatasetTypes = ''
			
			SELECT @allowedDatasetTypes = @allowedDatasetTypes + ', ' + Dataset_Type
			FROM T_Instrument_Allowed_Dataset_Type 
			WHERE Instrument = @instrumentName
			ORDER BY Dataset_Type

			-- Remove the leading two characters
			If Len(@allowedDatasetTypes) > 0
				Set @allowedDatasetTypes = Substring(@allowedDatasetTypes, 3, Len(@allowedDatasetTypes))
			
			set @message = 'Dataset Type "' + @DatasetType + '" is invalid for instrument "' + @instrumentName + '"; valid types are "' + @allowedDatasetTypes + '"'
			return 51014
		end

	End

Done:
	---------------------------------------------------
	-- Verify that dataset type is valid for given instrument
	---------------------------------------------------
	return @myError
GO
GRANT VIEW DEFINITION ON [dbo].[ValidateInstrumentAndDatasetType] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[ValidateInstrumentAndDatasetType] TO [PNL\D3M580] AS [dbo]
GO
