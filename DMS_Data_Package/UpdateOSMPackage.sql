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
		---------------------------------------------------\
		
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

		-- rollback any open transactions
		IF (XACT_STATE()) <> 0
			ROLLBACK TRANSACTION;

	END CATCH
	RETURN @myError

/*
GRANT EXECUTE ON UpdateOSMPackage TO DMS2_SP_User
GRANT EXECUTE ON UpdateOSMPackage TO DMS_SP_User
*/ 
GO
GRANT EXECUTE ON [dbo].[UpdateOSMPackage] TO [DMS_SP_User] AS [dbo]
GO
