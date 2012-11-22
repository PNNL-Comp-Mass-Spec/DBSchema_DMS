/****** Object:  StoredProcedure [dbo].[MapMACJobParameters] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[MapMACJobParameters]
/****************************************************
**
**  Desc: 
**  Verify configuration and contents of a data package
**  suitable for running a given MAC job from job template 
**
**  Uses temp table #MACJobParams created by caller
**	
**  Return values: 0: success, otherwise, error code
**
**
**  Auth:	grk
**  Date:	
**  10/29/2012 grk - Initial release
**  11/01/2012 grk - eliminated job template
**
*****************************************************/
(
	@scriptName varchar(64) ,
	@jobParam VARCHAR(8000),
	@tool VARCHAR(64) output,
	@mode VARCHAR(12) = 'map', 
	@message VARCHAR(512) output
)
AS
	set nocount on
	
	declare @myError int = 0
	declare @myRowCount int = 0

	DECLARE @DebugMode tinyint = 0

	BEGIN TRY                

		---------------------------------------------------
		-- map entry fields to table
		---------------------------------------------------
		
		DECLARE @entryValuesXML XML = CONVERT(XML, @jobParam)
		
		declare @entryValues table (
			[Name] varchar(128),
			[Value] varchar(4000)
		)

		INSERT INTO @entryValues
			([Name], Value)
		SELECT 
			xmlNode.value('@Name', 'varchar(64)') as [Name],
			xmlNode.value('@Value', 'varchar(4000)') as [Value]
		FROM
			@entryValuesXML.nodes('//Param') AS R(xmlNode)

		---------------------------------------------------
		-- set parameter values according to entry field values
		-- and mapping for template
		---------------------------------------------------
		
		IF @scriptName IN ('Isobaric_Labeling')
		BEGIN 
			DECLARE @experimentLabelling VARCHAR(128) = ''
			SELECT @experimentLabelling = Value FROM @entryValues WHERE [Name]='Experiment_Labelling'
		
			DECLARE @extractionType VARCHAR(128)
			SELECT @extractionType =  CASE WHEN @tool = 'sequest' THEN 'Sequest First Hits'
									WHEN @tool = 'msgfdb' THEN 'MSGFDB First Hits'
									ELSE '??' END
		
			IF @extractionType = '??'
				RAISERROR('Search tool "%s" not recognized', 11, 26, @tool)												

			DECLARE @apeWorflowStepList VARCHAR(256) = @tool + ', ' + 'default, no_ascore, no_precursor_filter, ' + @experimentLabelling
		
			UPDATE #MACJobParams
			SET [Value] = @apeWorflowStepList
			WHERE [Name] = 'ApeWorflowStepList'						

			UPDATE #MACJobParams
			SET [Value] = @extractionType
			WHERE [Name] = 'ExtractionType'						

		END 
	
	END TRY
	BEGIN CATCH 
		EXEC FormatErrorMessage @message output, @myError output
	END CATCH
	return @myError
	
	

GO
