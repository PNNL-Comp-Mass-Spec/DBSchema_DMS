/****** Object:  StoredProcedure [dbo].[GetPSMJobDefinitions] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE dbo.GetPSMJobDefinitions
/****************************************************
**
**	Desc: Returns sets of parameters for setting up
**  PSM-type job request entry page
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters:
**
**	Auth:	grk
**	Date:	11/15/2012 grk - Initial version
**			11/20/2012 mem - Now returning organism name, protein collection list, and protein options list
**			11/20/2012 grk - removed extra RETURN that was blocking error return
**			02/23/2016 mem - Add set XACT_ABORT on
**    
*****************************************************/
(
    @datasets varchar(max) OUTPUT,		-- Input/output parameter; comma-separated list of datasets; will be alphabetized after removing duplicates
	@metadata varchar(2048) OUTPUT,		-- Output parameter; table of metadata with columns separated by colons and rows separated by vertical bars
    @defaults varchar(2048) OUTPUT,		-- default values
    @mode varchar(12) = 'PSM',			-- someday, other types?
    @message varchar(512) output
)
AS
	Set XACT_ABORT, nocount on

	Declare @myError int = 0
	Declare @myRowCount int = 0
	
	BEGIN TRY 
	 	DECLARE
		@toolName varchar(64) ,
		@jobTypeName varchar(64) ,
		@jobTypeDesc varchar(255) ,
		@DynMetOxEnabled tinyint ,    
		@StatCysAlkEnabled tinyint ,
		@DynSTYPhosEnabled tinyint ,
		@organismName varchar(128) ,
		@protCollNameList varchar(1024) ,
		@protCollOptionsList varchar(256) 
		EXEC @myError = GetPSMJobDefaults
							@datasets = @datasets output,
							@Metadata = @metadata output,
							@toolName = @toolName output,
							@jobTypeName = @jobTypeName output,
							@jobTypeDesc = @jobTypeDesc output,
							@DynMetOxEnabled = @DynMetOxEnabled output,
							@StatCysAlkEnabled = @StatCysAlkEnabled output,
							@DynSTYPhosEnabled = @DynSTYPhosEnabled output,
							@organismName = @organismName output,
							@protCollNameList = @protCollNameList output,
							@protCollOptionsList = @protCollOptionsList output,
							@message = @message output


		SET @defaults = ''
		SET @defaults = @defaults + 'ToolName' +              ':' + @toolName                                + '|'
		SET @defaults = @defaults + 'JobTypeName' +           ':' + @jobTypeName                             + '|'
		SET @defaults = @defaults + 'JobTypeDesc' +           ':' + @jobTypeDesc                             + '|'
		SET @defaults = @defaults + 'DynMetOxEnabled' +       ':' + convert(varchar(12), @DynMetOxEnabled)   + '|'
		SET @defaults = @defaults + 'StatCysAlkEnabled' +     ':' + convert(varchar(12), @StatCysAlkEnabled) + '|'
		SET @defaults = @defaults + 'DynSTYPhosEnabled' +     ':' + convert(varchar(12), @DynSTYPhosEnabled) + '|'
		SET @defaults = @defaults + 'OrganismName' +          ':' + @organismName                            + '|'
		SET @defaults = @defaults + 'ProteinCollectionList' + ':' + @protCollNameList                        + '|'
		SET @defaults = @defaults + 'ProteinOptionsList' +    ':' + @protCollOptionsList                     + '|'
	
	END TRY
	BEGIN CATCH 
		EXEC FormatErrorMessage @message output, @myError output
		
		-- rollback any open transactions
		If (XACT_STATE()) <> 0
			ROLLBACK TRANSACTION;
	END CATCH
	RETURN @myError

GO
GRANT EXECUTE ON [dbo].[GetPSMJobDefinitions] TO [DMS_SP_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[GetPSMJobDefinitions] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[GetPSMJobDefinitions] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[GetPSMJobDefinitions] TO [PNL\D3M580] AS [dbo]
GO
