/****** Object:  StoredProcedure [dbo].[AddJobRequestPSM] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE AddJobRequestPSM
/****************************************************
**
**  Desc: 
**  Create a job from simplified interface 
**	
**  Return values: 0: success, otherwise, error code
**
**
**  Auth:	grk
**  Date:	11/14/2012 grk - Initial release
**			11/16/2012 grk - Added
**			11/20/2012 grk - Added @organismName
**			11/21/2012 mem - Now calling CreatePSMJobRequest
**			12/13/2012 mem - Added support for @mode='preview'
**			02/23/2016 mem - Add set XACT_ABORT on
**			04/12/2017 mem - Log exceptions to T_Log_Entries
**
*****************************************************/
(
	@requestID INT OUTPUT,
	@requestName VARCHAR(128),
	@datasets VARCHAR(max) output,	
	@comment VARCHAR(512),
	@ownerPRN VARCHAR(64),
	@organismName varchar(128),
	@protCollNameList varchar(4000),
    @protCollOptionsList varchar(256),
    @toolName varchar(64),
    @jobTypeName varchar(64),
	@ModificationDynMetOx varchar(24),    
	@ModificationStatCysAlk varchar(24),
	@ModificationDynSTYPhos varchar(24),
	@mode VARCHAR(12) = 'add',			-- 'add', 'preview', or 'debug'
	@message VARCHAR(512) output,
	@callingUser VARCHAR(128) = ''
)
AS
	Set XACT_ABORT, nocount on
	
	DECLARE @myError int = 0
	DECLARE @myRowCount int = 0
	
	DECLARE @DebugMode tinyint = 0

	BEGIN TRY                
		---------------------------------------------------
		-- 
		---------------------------------------------------
		
		
		IF @mode = 'debug'	
		BEGIN --<debug>
			set @message = 'Debug mode; nothing to do'					
		END --<debug>               

		---------------------------------------------------
		-- add mode
		---------------------------------------------------
        
		IF @mode in ('add', 'preview')
		BEGIN --<add>

			DECLARE @previewMode tinyint = 0
		
			If @mode = 'preview'
				Set @previewMode = 1
					
			DECLARE
				@DynMetOxEnabled TINYINT = 0,    
				@StatCysAlkEnabled tinyint = 0,
				@DynSTYPhosEnabled tinyint = 0
				
			SELECT 	@DynMetOxEnabled = CASE WHEN @ModificationDynMetOx = 'Yes'	THEN 1 ELSE 0 END 
			SELECT 	@StatCysAlkEnabled = CASE WHEN @ModificationStatCysAlk = 'Yes'	THEN 1 ELSE 0 END 
			SELECT 	@DynSTYPhosEnabled = CASE WHEN @ModificationDynSTYPhos = 'Yes'	THEN 1 ELSE 0 END 
				
			EXEC @myError = CreatePSMJobRequest
								@requestID = @requestID output,
								@requestName = @requestName ,
								@datasets = @datasets output,
								@toolName = @toolName ,
								@jobTypeName = @jobTypeName ,
								@protCollNameList = @protCollNameList ,
								@protCollOptionsList = @protCollOptionsList ,       
								@DynMetOxEnabled = @DynMetOxEnabled,    
								@StatCysAlkEnabled = @StatCysAlkEnabled,
								@DynSTYPhosEnabled = @DynSTYPhosEnabled,
								@comment = @comment ,
								@ownerPRN = @ownerPRN ,
								@previewMode = @previewMode,
								@message = @message  output,
								@callingUser = @callingUser

		END --<add>

	END TRY
	BEGIN CATCH 
		EXEC FormatErrorMessage @message output, @myError output

		-- rollback any open transactions
		IF (XACT_STATE()) <> 0
			ROLLBACK TRANSACTION;

		Exec PostLogEntry 'Error', @message, 'AddJobRequestPSM'
	END CATCH
	RETURN @myError

GO
GRANT VIEW DEFINITION ON [dbo].[AddJobRequestPSM] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddJobRequestPSM] TO [DMS_SP_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddJobRequestPSM] TO [DMS2_SP_User] AS [dbo]
GO
