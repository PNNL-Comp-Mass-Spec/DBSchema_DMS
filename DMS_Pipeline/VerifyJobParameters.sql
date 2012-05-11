/****** Object:  StoredProcedure [dbo].[VerifyJobParameters] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE VerifyJobParameters
/****************************************************
**
**  Desc: 
**  Check input parameters against the definition for the script
**	
**  Return values: 0: success, otherwise, error code
**
**
**  Auth:	grk
**  Date:	10/06/2010 grk - Initial release
**			11/25/2010 mem - Now validating that the script exists in T_Scripts
**
*****************************************************/
(
	@ParamInput varchar(max),
	@scriptName varchar(64),
	@message varchar(512) output
)
AS
	set nocount on
	
	declare @myError int
	declare @myRowCount int

	set @myError = 0
	set @myRowCount = 0

	---------------------------------------------------
	-- Get parameter definition
	-- This is null for most scripts
	---------------------------------------------------
	
	DECLARE @ParamDefinition xml
	--
	SELECT @ParamDefinition = Parameters
	FROM   dbo.T_Scripts
	WHERE  Script = @scriptName
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	
	If @myRowCount= 0
	Begin
		SET @message = 'Script not found in T_Scripts: ' + IsNull(@scriptName, '??')
		SET @myError = 50
		Print @message
		return @myError
	End
	
	---------------------------------------------------
	-- Extract parameter definitions (if any) into temp table
	---------------------------------------------------
	
	CREATE TABLE #TPD (
		[Section] Varchar(128),
		[Name] Varchar(128),
		[Value] Varchar(max),
		[Reqd] Varchar(32)
	)

	INSERT INTO #TPD ([Section], [Name], [Value], [Reqd])	
	SELECT
		xmlNode.value('@Section', 'nvarchar(256)') Section,
		xmlNode.value('@Name', 'nvarchar(256)') Name,
		xmlNode.value('@Value', 'nvarchar(4000)') VALUE,
		ISNULL(xmlNode.value('@Reqd', 'nvarchar(32)'), 'No') as Reqd
	FROM
		@ParamDefinition.nodes('//Param') AS R(xmlNode)

	---------------------------------------------------
	-- extract input parameters into temp table
	---------------------------------------------------
		--
	CREATE TABLE #TJP (
		[Section] Varchar(128),
		[Name] Varchar(128),
		[Value] Varchar(max)
	)

	DECLARE @ParamValue XML
	SET @ParamValue = CONVERT(XML, @ParamInput)
	
	INSERT INTO #TJP ([Section], [Name], [Value])	
	SELECT
		xmlNode.value('@Section', 'nvarchar(256)') Section,
		xmlNode.value('@Name', 'nvarchar(256)') Name,
		xmlNode.value('@Value', 'nvarchar(4000)') Value
	FROM
		@ParamValue.nodes('//Param') AS R(xmlNode)

	---------------------------------------------------
	-- Cross check to make sure required parameters are defined in #TJP (populated using @ParamInput)
	---------------------------------------------------
	DECLARE @s VARCHAR(8000)
	SET @s = ''

	SELECT 
		@s = @s + #TPD.Section + '/' + #TPD.Name + ','
	FROM
		#TPD
		LEFT OUTER JOIN #TJP ON #TPD.Name = #TJP.Name
						AND #TPD.Section = #TJP.Section
	WHERE
		#TPD.Reqd = 'Yes'
		AND ISNULL(#TJP.Value, '') = ''
		
	IF @s <> ''
	BEGIN
		SET @message = 'Missing required parameters:' + @s
		SET @myError = 52
		Print @message
		return @myError
	END
	
	return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[VerifyJobParameters] TO [Limited_Table_Write] AS [dbo]
GO
