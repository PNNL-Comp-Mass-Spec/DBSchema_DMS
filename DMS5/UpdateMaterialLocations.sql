/****** Object:  StoredProcedure [dbo].[UpdateMaterialLocations] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Procedure dbo.UpdateMaterialLocations
/****************************************************
**
**	Desc: 
**	Change properties of given set of material locations 
**
**	@locationList will look like this:
**
**      <r n="80B.na.na.na.na" i="425" a="Status" v="Active" />
**      <r n="80B.2.na.na.na" i="439" a="Status" v="Active" />
**      <r n="80B.3.3.na.na" i="558" a="Status" v="Active" />
**
**	Return values: 0: success, otherwise, error code
**
**	Parameters: 
**
**	Auth: 	grk
**	Date:	06/02/2013 grk - initial release
**			06/03/2013 grk - added action attribute to XML
**			06/06/2013 grk - added code to update status
**			02/23/2016 mem - Add set XACT_ABORT on
**			11/08/2016 mem - Use GetUserLoginWithoutDomain to obtain the user's network login
**			11/10/2016 mem - Pass '' to GetUserLoginWithoutDomain
**			04/12/2017 mem - Log exceptions to T_Log_Entries
**			06/16/2017 mem - Restrict access using VerifySPAuthorized
**			08/01/2017 mem - Use THROW if not authorized
**    
*****************************************************/
(
	@locationList text,
	@message varchar(512) OUTPUT,
	@callingUser varchar(128) = '',
	@infoOnly tinyint = 0				-- Set to 1 to preview the changes that would be made
)
As
	Set XACT_ABORT, nocount on

	declare @myError int = 0
	declare @myRowCount int = 0

	Declare @Msg2 varchar(512)
	
	DECLARE @xml AS xml
	SET CONCAT_NULL_YIELDS_NULL ON
	SET ANSI_PADDING ON

	SET @message = ''

	---------------------------------------------------
	-- Verify that the user can execute this procedure from the given client host
	---------------------------------------------------
		
	Declare @authorized tinyint = 0	
	Exec @authorized = VerifySPAuthorized 'UpdateMaterialLocations', @raiseError = 1
	If @authorized = 0
	Begin
		THROW 51000, 'Access denied', 1;
	End
	
	BEGIN TRY 

		-----------------------------------------------------------
		-- Validate the inputs
		-----------------------------------------------------------

		If IsNull(@callingUser, '') = ''
			SET @callingUser = dbo.GetUserLoginWithoutDomain('')

		Set @infoOnly = IsNull(@infoOnly, 0)

		-----------------------------------------------------------
		-- temp table to hold factors
		-----------------------------------------------------------
		--
		CREATE TABLE #TMP (
			Location VARCHAR(256),
			ID VARCHAR(256) NULL,
			[Action] VARCHAR(256) NULL,
			[Value] VARCHAR(256) NULL,
			[Old_Value] VARCHAR(256) NULL
		)

		-----------------------------------------------------------
		-- Copy @locationList text variable into the XML variable
		-----------------------------------------------------------
		SET @xml = @locationList

		-----------------------------------------------------------
		-- populate temp table with new parameters
		-----------------------------------------------------------
		--
		INSERT INTO #TMP
			(Location, ID, [Action], [Value])
		SELECT
			xmlNode.value('@n', 'nvarchar(256)') Location,
			xmlNode.value('@i', 'nvarchar(256)') ID,
			xmlNode.value('@a', 'nvarchar(256)') [Action],
			xmlNode.value('@v', 'nvarchar(256)') [Value]			
		FROM @xml.nodes('//r') AS R(xmlNode)
		--
		SELECT @myError = @@error, @myRowCount = @@rowcount
		--
		if @myError <> 0
			RAISERROR ('Error reading in location list', 11, 9)
			

		-----------------------------------------------------------
		-- Get current status values
		-----------------------------------------------------------
		
		UPDATE [#TMP]
			SET Old_Value = TML.Status
		FROM T_Material_Locations AS TML
			INNER JOIN [#TMP] ON TML.Tag = [#TMP].Location
		WHERE ( [#TMP].Action = 'Status' )

		-----------------------------------------------------------
		-- Update status values that have changed
		-----------------------------------------------------------

		IF @infoOnly = 0
		BEGIN
			UPDATE T_Material_Locations
			SET Status = [#TMP].Value
			FROM [#TMP]
				INNER JOIN T_Material_Locations ON T_Material_Locations.Tag = [#TMP].Location
			WHERE ( [#TMP].Action = 'Status' )
				AND ( NOT ( [#TMP].Value = ISNULL([#TMP].Old_Value, '') ) )
		END			

		-----------------------------------------------------------
		IF @infoOnly > 0
		BEGIN
			SELECT * FROM #TMP
		END			

		---------------------------------------------------
		-- Log SP usage
		---------------------------------------------------
/*
		IF @infoOnly = 0
		BEGIN 
			Declare @UsageMessage varchar(512)
			Set @UsageMessage = Cast(@locationList as varchar(512))			
			Exec PostUsageLogEntry 'UpdateMaterialLocations', @UsageMessage
		END
*/
	END TRY
	BEGIN CATCH 
		EXEC FormatErrorMessage @message OUTPUT, @myError OUTPUT
		Exec PostLogEntry 'Error', @message, 'UpdateMaterialLocations'
	END CATCH
	RETURN @myError


GO
GRANT VIEW DEFINITION ON [dbo].[UpdateMaterialLocations] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[UpdateMaterialLocations] TO [DMS_SP_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[UpdateMaterialLocations] TO [DMS2_SP_User] AS [dbo]
GO
