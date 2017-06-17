/****** Object:  StoredProcedure [dbo].[UpdateOSMPackage] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE dbo.UpdateOSMPackage
/****************************************************
**
**  Desc: 
**  Update or delete given OSM Package
**
**  Return values: 0: success, otherwise, error code
**
**
**  Auth:	grk
**  Date:	07/08/2013 grk - Initial release
**			02/23/2016 mem - Add set XACT_ABORT on
**			05/18/2016 mem - Log errors to T_Log_Entries
**			06/16/2017 mem - Restrict access using VerifySPAuthorized
**
*****************************************************/
(
	@osmPackageID INT,
	@mode VARCHAR(32),
	@message VARCHAR(512) output,
	@callingUser VARCHAR(128) = ''
)
AS
	Set XACT_ABORT, nocount on
	
	DECLARE @myError int = 0
	DECLARE @myRowCount int = 0
	SET @message = ''

	DECLARE @DebugMode tinyint = 0

	BEGIN TRY
	
	---------------------------------------------------
	-- Verify that the user can execute this procedure from the given client host
	---------------------------------------------------
		
	Declare @authorized tinyint = 0	
	Exec @authorized = VerifySPAuthorized 'UpdateOSMPackage', @raiseError = 1
	If @authorized = 0
	Begin
		RAISERROR ('Access denied', 11, 3)
	End

	---------------------------------------------------
	-- verify OSM package exists
	---------------------------------------------------
	
	IF @mode = 'delete'
	BEGIN --<delete>
	
		---------------------------------------------------
		-- start transaction
		---------------------------------------------------
		--
		declare @transName varchar(32)
		set @transName = 'UpdateOSMPackage'
		begin transaction @transName

		---------------------------------------------------
		-- 'delete' (mark as inactive) associated file attachments
		---------------------------------------------------

		UPDATE S_File_Attachment
		SET [Active] = 0
		WHERE Entity_Type = 'osm_package'
		AND Entity_ID = @osmPackageID

		---------------------------------------------------
		-- remove OSM package from table
		---------------------------------------------------
		
		DELETE  FROM dbo.T_OSM_Package
		WHERE   ID = @osmPackageID

		commit transaction @transName
	
	END --<delete>
	
	IF @mode = 'test'
	BEGIN
		RAISERROR ('Test: %d', 11, 20, @osmPackageID)
	END
	
	END TRY
	BEGIN CATCH 
		EXEC FormatErrorMessage @message output, @myError output

		Declare @msgForLog varchar(512) = ERROR_MESSAGE()
		
		-- rollback any open transactions
		IF (XACT_STATE()) <> 0
			ROLLBACK TRANSACTION;
		
		Exec PostLogEntry 'Error', @msgForLog, 'UpdateOSMPackage'
		
	END CATCH
	RETURN @myError

/*
GRANT EXECUTE ON UpdateOSMPackage TO DMS2_SP_User
GRANT EXECUTE ON UpdateOSMPackage TO DMS_SP_User
*/ 
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateOSMPackage] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[UpdateOSMPackage] TO [DMS_SP_User] AS [dbo]
GO
