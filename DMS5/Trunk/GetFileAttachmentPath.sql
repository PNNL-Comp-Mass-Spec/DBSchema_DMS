/****** Object:  UserDefinedFunction [dbo].[GetFileAttachmentPath] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION dbo.GetFileAttachmentPath
/****************************************************
**
**	Desc: 
**  Returns storage path for file attachment
**  for the given DMS tracking entity
**
**	Return value: person
**
**	Parameters: 
**
**	Auth:	grk
**	Date:	04/16/2011
**          04/26/2011 grk - added sample prep request
**    
*****************************************************/
(
	@entityType VARCHAR(64),
	@entityID VARCHAR(256)
)
RETURNS VARCHAR(256)
AS
	BEGIN
	DECLARE @spreadFolder VARCHAR(24) = 'spread'
	DECLARE @created DATETIME = '1/1/1900'
	
	-------------------------------------------------------
	IF @entityType = 'campaign' 
	BEGIN
		IF ISNUMERIC(@entityID) = 0
		BEGIN 
			SELECT 
			@entityID = CONVERT(VARCHAR(24), Campaign_ID),
			@created = CM_created
			FROM dbo.T_Campaign 
			WHERE Campaign_Num = @entityID
			SET @spreadFolder = CONVERT(VARCHAR(12), DATEPART(year, @created)) + '_' + CONVERT(VARCHAR(12), DATEPART(month, @created))
		END 
		ELSE 
		BEGIN
			SELECT 
			@created = CM_created
			FROM dbo.T_Campaign 
			WHERE Campaign_ID = @entityID
			SET @spreadFolder = CONVERT(VARCHAR(12), DATEPART(year, @created)) + '_' + CONVERT(VARCHAR(12), DATEPART(month, @created))
		END 
	END
	-------------------------------------------------------
	ELSE IF @entityType = 'experiment' 
	BEGIN
		IF ISNUMERIC(@entityID) = 0
		BEGIN 
			SELECT
			@entityID = CONVERT(VARCHAR(24), Exp_ID), 
			@created = EX_created
			FROM T_Experiments
			WHERE Experiment_Num = @entityID
			SET @spreadFolder = CONVERT(VARCHAR(12), DATEPART(year, @created)) + '_' + CONVERT(VARCHAR(12), DATEPART(month, @created))
		END 
		ELSE
		BEGIN
			SELECT 
			@created = EX_created
			FROM T_Experiments
			WHERE Exp_ID = @entityID
			SET @spreadFolder = CONVERT(VARCHAR(12), DATEPART(year, @created)) + '_' + CONVERT(VARCHAR(12), DATEPART(month, @created))	
		END 
	END
	-------------------------------------------------------
	ELSE IF @entityType = 'dataset' 
	BEGIN
		IF ISNUMERIC(@entityID) = 0
		BEGIN 
			SELECT 		
			@entityID = CONVERT(VARCHAR(24), Dataset_ID),
			@created = DS_created
			FROM T_Dataset
			WHERE Dataset_Num = @entityID
			SET @spreadFolder = CONVERT(VARCHAR(12), DATEPART(year, @created)) + '_' + CONVERT(VARCHAR(12), DATEPART(month, @created))
		END 
		ELSE
		BEGIN 
			SELECT 		
			@created = DS_created
			FROM T_Dataset
			WHERE Dataset_ID = @entityID
			SET @spreadFolder = CONVERT(VARCHAR(12), DATEPART(year, @created)) + '_' + CONVERT(VARCHAR(12), DATEPART(month, @created))	
		END 
	END 
	-------------------------------------------------------
	IF @entityType = 'sample_prep_request' 
	BEGIN
		IF ISNUMERIC(@entityID) = 0
		BEGIN 
			SELECT 
			@entityID = CONVERT(VARCHAR(24), ID),
			@created = Created
			FROM dbo.T_Sample_Prep_Request 
			WHERE Request_Name = @entityID
			SET @spreadFolder = CONVERT(VARCHAR(12), DATEPART(year, @created)) + '_' + CONVERT(VARCHAR(12), DATEPART(month, @created))
		END 
		ELSE 
		BEGIN
			SELECT 
			@created = Created
			FROM dbo.T_Sample_Prep_Request 
			WHERE ID = @entityID
			SET @spreadFolder = CONVERT(VARCHAR(12), DATEPART(year, @created)) + '_' + CONVERT(VARCHAR(12), DATEPART(month, @created))
		END 
	END
	-------------------------------------------------------
	ELSE IF @entityType = 'instrument_operation_history' 
	BEGIN
		SET @entityType = 'instrument_operation'
		SELECT @created = Entered
		FROM dbo.T_Instrument_Operation_History
		WHERE ID = @entityID 
		SET @spreadFolder = CONVERT(VARCHAR(12), DATEPART(year, @created))
	END 
	-------------------------------------------------------
	ELSE IF @entityType = 'instrument_config_history' 
	BEGIN
		SET @entityType = 'instrument_config'
		SELECT @created = Entered
		FROM dbo.T_Instrument_Config_History
		WHERE ID = @entityID 
		SET @spreadFolder = CONVERT(VARCHAR(12), DATEPART(year, @created))
	END 
	-------------------------------------------------------
	ELSE IF @entityType = 'lc_cart_config_history' 
	BEGIN
		SET @entityType = 'lc_cart_config'
		SELECT @created = Entered
		FROM dbo.T_LC_Cart_Config_History
		WHERE ID = @entityID 
		SET @spreadFolder = CONVERT(VARCHAR(12), DATEPART(year, @created))
	END 
	
	RETURN @entityType + '/' + @spreadFolder + '/' + @entityID
	END

GO
GRANT EXECUTE ON [dbo].[GetFileAttachmentPath] TO [DMS2_SP_User] AS [dbo]
GO
