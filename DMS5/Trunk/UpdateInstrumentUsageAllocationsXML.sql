/****** Object:  StoredProcedure [dbo].[UpdateInstrumentUsageAllocationsXML] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE UpdateInstrumentUsageAllocationsXML
/****************************************************
**
**	Desc: 
**		Update requested instrument usage allocation from input XML list 
**
**	@parameterList will look like this (for setting values):
**
**	<c fiscal_year="2012"/>
**	<r p="29591" g="FT" a="23.2" x="Comment1"/>
**	<r p="33200" g="FT" a="102.1" x="Comment2"/>
**	<r p="34696" g="FT" a="240" />
**	<r p="34708" g="FT" a="177.7" x="Comment3"/>
**
**  or this (for transferring hours between two proposals):
**
**	<c fiscal_year="2012"/>
**	<r o="i" p="29591" g="FT" a="14.5" x="Comment"/>
**	<r o="d" p="33200" g="FT" a="14.5" x="Comment"/>
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**	Auth: 	grk
**	Date:	03/28/2012 grk - Initial release
**          03/30/2012 grk - Added change command capability
**			03/30/2012 mem - Added support for x="Comment" in the XML
**						   - Now calling UpdateInstrumentUsageAllocationsWork to apply the updates
**    
*****************************************************/
(
	@parameterList text = '',				-- Either provide XML via @parameterList or provide specific allocation hours via the following "float" parameters and @comment parameter
	@message varchar(512) OUTPUT,
	@callingUser varchar(128) = '',
	@infoOnly tinyint = 0					-- Set to 1 to preview the changes that would be made
)
As
	SET NOCOUNT ON 

	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0

	Declare @fiscalYear varchar(24)
	Declare @fy int

	Declare @Msg2 varchar(512)
	
	DECLARE @xml AS xml
	SET CONCAT_NULL_YIELDS_NULL ON
	SET ANSI_PADDING ON

	---------------------------------------------------
	---------------------------------------------------
	BEGIN TRY 

		-----------------------------------------------------------
		-- Validate the inputs
		-----------------------------------------------------------

		SET @message = ''
		Set @infoOnly = IsNull(@infoOnly, 0)

		-----------------------------------------------------------
		-- temp table to hold operations
		-----------------------------------------------------------
		--
		CREATE TABLE #T_OPS (
			Entry_ID int Identity(1,1),
			Allocation varchar(128) NULL,
			InstGroup varchar(128) null,
			Proposal varchar(128) null,
			Comment varchar(256) null,
			FY int,
			Operation CHAR(1) NULL -- 'i' -> increment, 'd' -> decrement, anything else -> set
		)
	
		-----------------------------------------------------------
		-- Copy @parameterList text variable into the XML variable
		-----------------------------------------------------------
		SET @xml = @parameterList
	
		-----------------------------------------------------------
		-- resolve fiscal year
		-----------------------------------------------------------
		--
		
		SELECT @fiscalYear = xmlNode.value('@fiscal_year', 'nvarchar(24)')
		FROM @xml.nodes('//c') AS R(xmlNode)

		If IsNull(@fiscalYear, '') = ''
		Begin
			Set @fy = DATEPART(YEAR, GETDATE())
		End
		ELSE 
		BEGIN
			SET @fy = CONVERT(INT, @fiscalYear)
		END
				
		-----------------------------------------------------------
		-- populate operations table from input parameters
		-----------------------------------------------------------
		--
		INSERT INTO #T_OPS
			(Operation, Proposal, InstGroup, Allocation, Comment, FY)
		SELECT
			IsNull(xmlNode.value('@o', 'nvarchar(256)'), '') Operation,			-- If missing from the XML, then the merge will treat this as "Set"
			xmlNode.value('@p', 'nvarchar(256)') Proposal,
			xmlNode.value('@g', 'nvarchar(256)') InstGroup,
			xmlNode.value('@a', 'nvarchar(256)') Allocation,
			IsNull(xmlNode.value('@x', 'nvarchar(256)'), '') Comment,
			@fy AS FY
		FROM @xml.nodes('//r') AS R(xmlNode)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
			RAISERROR ('Error trying to populate "set" operations table', 11, 1)


		-----------------------------------------------------------
		-- Call UpdateInstrumentUsageAllocationsWork to perform the work
		-----------------------------------------------------------
		--
		EXEC @myError = UpdateInstrumentUsageAllocationsWork @fy, @message output, @callingUser, @infoOnly
		

	END TRY
	BEGIN CATCH 
		EXEC FormatErrorMessage @message output, @myError output
		
		-- rollback any open transactions
		IF (XACT_STATE()) <> 0
			ROLLBACK TRANSACTION;
	END CATCH
	return @myError

GO
