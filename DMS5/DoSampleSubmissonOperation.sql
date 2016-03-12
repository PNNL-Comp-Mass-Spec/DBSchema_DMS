/****** Object:  StoredProcedure [dbo].[DoSampleSubmissonOperation] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE DoSampleSubmissonOperation
/****************************************************
**
**  Desc: 
**    Performs operation given by @mode
**    on entity given by @ID
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**  Auth:	grk
**  Date:	05/07/2010 grk - initial release
**			02/23/2016 mem - Add set XACT_ABORT on
**    
** Pacific Northwest National Laboratory, Richland, WA
** Copyright 2010, Battelle Memorial Institute
*****************************************************/
(
	@ID int,
	@mode varchar(12),
	@message varchar(512) output,
	@callingUser varchar(128) = ''
)
As
	Set XACT_ABORT, nocount on

	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0

	set @message = ''

	BEGIN TRY
		---------------------------------------------------
		-- 
		---------------------------------------------------
		--
		if @mode = 'make_folder'
		begin
			---------------------------------------------------
			-- get storage path from sample submission
			--
			DECLARE @storagePath INT
			SET @storagePath = 0
			--
			SELECT
			  @storagePath = ISNULL(Storage_Path, 0)
			FROM
			  T_Sample_Submission
			WHERE
				ID =  @ID

			---------------------------------------------------
			-- if storage path not defined, get valid path ID and update sample submission
			--
			IF @storagePath = 0
			BEGIN 
				--
				SELECT
					@storagePath = ID
				FROM
					T_Prep_File_Storage
				WHERE
					State = 'Active'
					AND Purpose = 'Sample_Prep'
				--
				IF @storagePath = 0
					RAISERROR('Storage path for files could not be found', 11, 24)
				--
				UPDATE
					T_Sample_Submission
				SET
					Storage_Path = @storagePath
				WHERE
					ID = @ID
			END

			EXEC @myError = CallSendMessage @ID,'sample_submission', @message output
			--
			if @myError <> 0
				RAISERROR ('CallSendMessage:%s', 11, 27, @message)
		end

	END TRY
	BEGIN CATCH 
		EXEC FormatErrorMessage @message output, @myError output
	END CATCH
	return @myError

GO
GRANT EXECUTE ON [dbo].[DoSampleSubmissonOperation] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[DoSampleSubmissonOperation] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[DoSampleSubmissonOperation] TO [PNL\D3M578] AS [dbo]
GO
