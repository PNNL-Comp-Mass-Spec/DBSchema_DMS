/****** Object:  StoredProcedure [dbo].[AutoImportOSMPackageItems] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[AutoImportOSMPackageItems]
/****************************************************
**
**	Desc:
**  Calls auto import function for all currently 
**  active OSM packages
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters:
**
**    Auth: grk
**    Date: 
**          03/20/2013 grk - initial release
**
*****************************************************/
As
	set nocount on

	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0

	DECLARE @message varchar(512) = ''

 	---------------------------------------------------
	-- 
	---------------------------------------------------
	---------------------------------------------------
	---------------------------------------------------
	BEGIN TRY 
	
	 	---------------------------------------------------
		-- create and populate table to hold active package IDs
		---------------------------------------------------
		
		CREATE TABLE #PKGS (
			ID INT
			-- FUTURE: details about auto-update
		)
		
		INSERT INTO #PKGS
		        ( ID )
		SELECT ID FROM T_OSM_Package 
		WHERE State = 'Active'

 		---------------------------------------------------
		-- cycle through active packages and do auto import
		-- for each one
		---------------------------------------------------
		DECLARE 
				@itemType varchar(128) = '',
				@itemList VARCHAR(max) = '',
				@comment varchar(512) = '',
				@mode varchar(12) = 'auto-import',
				@callingUser varchar(128) = USER 
		
		DECLARE 
			@currentId INT = 0,
			@prevId INT = 0,
			@done INT = 0
		
		WHILE @done = 0
		BEGIN --<d>
			SET @currentId = 0
			
			SELECT TOP 1 @currentId = ID
			FROM #PKGS
			WHERE ID > @prevId
			ORDER BY ID
		
			IF @currentId = 0
			BEGIN --<e>
				SET @done = 1
			END --<e>
			ELSE 
			BEGIN  --<f>
				SET @prevId = @currentId
			
-- SELECT '->' + CONVERT(VARCHAR(12), @currentId)
			EXEC @myError = UpdateOSMPackageItems
								@currentId,
								@itemType,
								@itemList,
								@comment,
								@mode,
								@message output,
								@callingUser
			END --<f>
		END --<d>

  	---------------------------------------------------
 	---------------------------------------------------

	END TRY     
	BEGIN CATCH 
		EXEC FormatErrorMessage @message output, @myError output
		-- rollback any open transactions
		IF (XACT_STATE()) <> 0
			ROLLBACK TRANSACTION;
	END CATCH
	
 	---------------------------------------------------
	-- Exit
	---------------------------------------------------
	return @myError

	
GO
