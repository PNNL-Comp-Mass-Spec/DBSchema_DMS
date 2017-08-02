/****** Object:  StoredProcedure [dbo].[DoMaterialContainerOperation] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure DoMaterialContainerOperation
/****************************************************
**
**  Desc: Do an operation on a container, using the container name
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**	Auth:	grk
**	Date:	07/23/2008 grk - Initial version (ticket http://prismtrac.pnl.gov/trac/ticket/603)
**			10/01/2009 mem - Expanded error message
**			08/19/2010 grk - try-catch for error handling
**			02/23/2016 mem - Add set XACT_ABORT on
**			04/12/2017 mem - Log exceptions to T_Log_Entries
**			06/16/2017 mem - Restrict access using VerifySPAuthorized
**			08/01/2017 mem - Use THROW if not authorized
**    
** Pacific Northwest National Laboratory, Richland, WA
** Copyright 2008, Battelle Memorial Institute
*****************************************************/
(
	@name varchar(128),					-- Container name
	@mode varchar(32),					-- 'move_container', 'retire_container', 'retire_container_and_contents'
    @message varchar(512) output,
	@callingUser varchar (128) = ''
)
As
	Set XACT_ABORT, nocount on

	declare @myError int = 0
	declare @myRowCount int = 0
	
	set @message = ''
    declare @msg varchar(512)

	---------------------------------------------------
	-- Verify that the user can execute this procedure from the given client host
	---------------------------------------------------
		
	Declare @authorized tinyint = 0	
	Exec @authorized = VerifySPAuthorized 'DoMaterialContainerOperation', @raiseError = 1
	If @authorized = 0
	Begin
		THROW 51000, 'Access denied', 1;
	End

	BEGIN TRY 

	---------------------------------------------------
	-- Validate the name
	---------------------------------------------------
	declare @tmpID int
	set @tmpID = 0
	--
	SELECT @tmpID = ID
	FROM T_Material_Containers
	WHERE Tag = @name
	--
	if @tmpID = 0
	begin
		set @msg = 'Could not find the container for @mode="' + @mode + '" and @name="' + @name + '"'
		RAISERROR (@msg, 11, 1)
	end
	else
	begin
		declare
			@iMode varchar(32),
			@containerList varchar(4096),
			@newValue varchar(128),
			@comment varchar(512)

			set @iMode = @mode
			set @containerList = @tmpID
			set @newValue  = ''
			set @comment  = ''

		exec @myError = UpdateMaterialContainers
							@iMode,
							@containerList,
							@newValue,
							@comment,
							@msg output,
   							@callingUser


		if @myError <> 0
		begin
			RAISERROR (@msg, 11, 2)
		end
	end

	END TRY
	BEGIN CATCH 
		EXEC FormatErrorMessage @message output, @myError output
		
		-- rollback any open transactions
		IF (XACT_STATE()) <> 0
			ROLLBACK TRANSACTION;
			
		Exec PostLogEntry 'Error', @message, 'DoMaterialContainerOperation'
	END CATCH
	return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[DoMaterialContainerOperation] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[DoMaterialContainerOperation] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[DoMaterialContainerOperation] TO [Limited_Table_Write] AS [dbo]
GO
