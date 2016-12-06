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
**          08/23/2011 grk - added experiment_group
**          11/15/2011 grk - added sample_submission
**			04/06/2016 mem - Now using Try_Convert to convert from text to int
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
		Declare @campaignID int = Try_Convert(int, @entityID)
		
		IF @campaignID Is Null
		BEGIN 
			SELECT @entityID = CONVERT(varchar(24), Campaign_ID),
			       @created = CM_created
			FROM dbo.T_Campaign
			WHERE Campaign_Num = @entityID

			SET @spreadFolder = CONVERT(VARCHAR(12), DATEPART(year, @created)) + '_' + CONVERT(VARCHAR(12), DATEPART(month, @created))
		END 
		ELSE 
		BEGIN
			SELECT @created = CM_created
			FROM dbo.T_Campaign
			WHERE Campaign_ID = @campaignID

			SET @spreadFolder = CONVERT(VARCHAR(12), DATEPART(year, @created)) + '_' + CONVERT(VARCHAR(12), DATEPART(month, @created))
		END 
	END
	-------------------------------------------------------
	ELSE IF @entityType = 'experiment' 
	BEGIN
		Declare @experimentID int = Try_Convert(int, @entityID)
	
		IF @experimentID Is Null
		BEGIN 
			SELECT @entityID = CONVERT(varchar(24), Exp_ID),
			       @created = EX_created
			FROM T_Experiments
			WHERE Experiment_Num = @entityID

			SET @spreadFolder = CONVERT(VARCHAR(12), DATEPART(year, @created)) + '_' + CONVERT(VARCHAR(12), DATEPART(month, @created))
		END 
		ELSE
		BEGIN
			SELECT @created = EX_created
			FROM T_Experiments
			WHERE Exp_ID = @experimentID

			SET @spreadFolder = CONVERT(VARCHAR(12), DATEPART(year, @created)) + '_' + CONVERT(VARCHAR(12), DATEPART(month, @created))	
		END 
	END
	-------------------------------------------------------
	ELSE IF @entityType = 'dataset' 
	BEGIN
		Declare @datasetID int = Try_Convert(int, @entityID)
	
		IF @datasetID Is Null
		BEGIN 
			SELECT @entityID = CONVERT(varchar(24), Dataset_ID),
			       @created = DS_created
			FROM T_Dataset
			WHERE Dataset_Num = @entityID

			SET @spreadFolder = CONVERT(VARCHAR(12), DATEPART(year, @created)) + '_' + CONVERT(VARCHAR(12), DATEPART(month, @created))
		END 
		ELSE
		BEGIN 
			SELECT @created = DS_created
			FROM T_Dataset
			WHERE Dataset_ID = @datasetID

			SET @spreadFolder = CONVERT(VARCHAR(12), DATEPART(year, @created)) + '_' + CONVERT(VARCHAR(12), DATEPART(month, @created))	
		END 
	END 
	-------------------------------------------------------
	IF @entityType = 'sample_prep_request' 
	BEGIN
		Declare @samplePrepID int = Try_Convert(int, @entityID)
	
		IF @samplePrepID Is Null
		BEGIN 
			SELECT @entityID = CONVERT(varchar(24), ID),
			       @created = Created
			FROM dbo.T_Sample_Prep_Request
			WHERE Request_Name = @entityID

			SET @spreadFolder = CONVERT(VARCHAR(12), DATEPART(year, @created)) + '_' + CONVERT(VARCHAR(12), DATEPART(month, @created))
		END 
		ELSE 
		BEGIN
			SELECT @created = Created
			FROM dbo.T_Sample_Prep_Request
			WHERE ID = @samplePrepID

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
	-------------------------------------------------------
	ELSE IF @entityType = 'experiment_group' 
	BEGIN
		SET @entityType = 'experiment_group'
		SELECT @created = EG_Created
		FROM T_Experiment_Groups
		WHERE Group_ID = @entityID
		SET @spreadFolder = CONVERT(VARCHAR(12), DATEPART(year, @created))
	END 
	-------------------------------------------------------
	ELSE IF @entityType = 'sample_submission' 
    BEGIN
        SELECT  @created = Created
        FROM    dbo.T_Sample_Submission
        WHERE   ID = @entityID
        SET @spreadFolder = CONVERT(VARCHAR(12), DATEPART(year, @created)) + '_' + CONVERT(VARCHAR(12), DATEPART(month, @created))
    END
	
	RETURN @entityType + '/' + @spreadFolder + '/' + @entityID
	END

GO
GRANT VIEW DEFINITION ON [dbo].[GetFileAttachmentPath] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[GetFileAttachmentPath] TO [DMS2_SP_User] AS [dbo]
GO
