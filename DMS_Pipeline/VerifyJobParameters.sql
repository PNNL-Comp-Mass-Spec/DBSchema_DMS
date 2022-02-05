/****** Object:  StoredProcedure [dbo].[VerifyJobParameters] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[VerifyJobParameters]
/****************************************************
**
**  Desc: Check input parameters against the definition for the script
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:	grk
**  Date:	10/06/2010 grk - Initial release
**			11/25/2010 mem - Now validating that the script exists in T_Scripts
**			12/10/2013 grk - problem inserting null values into #TPD
**			04/08/2016 mem - Clear @message if null
**          03/10/2021 mem - Validate protein collection (or FASTA file) options for MaxQuant jobs
**                         - Rename the XML job parameters argument and make it an input/output argument
**                         - Add arguments @dataPackageID and @debugMode
**          01/31/2022 mem - Add support for MSFragger
**
*****************************************************/
(
	@jobParam varchar(8000) output,      -- Input / output parameter
	@scriptName varchar(64),
    @dataPackageID int,
	@message varchar(512) output,
    @debugMode tinyint = 0
)
AS
	Set nocount on
	
	Declare @myError int = 0
	Declare @myRowCount int = 0

	Set @message = IsNull(@message, '')
	Set @scriptName = IsNull(@scriptName, '')
    Set @dataPackageID = IsNull(@dataPackageID, 0)

    Declare @parameterFileName varchar(255)
    Declare @protCollNameList varchar(2000) = ''
    Declare @protCollOptionsList varchar(256) = ''
    Declare @organismName varchar(128) = ''
    Declare @organismDBName varchar(255) = ''    -- Aka legacy FASTA file

    Declare @paramFileType varchar(64) = ''
    Declare @paramFileValid tinyint

    Declare @collectionCountAdded int
    Declare @scriptBaseName Varchar(24)

	---------------------------------------------------
	-- Get parameter definition
	-- This is null for most scripts
	---------------------------------------------------
	
	Declare @ParamDefinition xml
	--
	SELECT @ParamDefinition = Parameters
	FROM   dbo.T_Scripts
	WHERE  Script = @scriptName
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	
	If @myRowCount= 0
	Begin
		Set @message = 'Script not found in T_Scripts: ' + IsNull(@scriptName, '??')
		Set @myError = 50100
		Print @message
		return @myError
	End
	
	---------------------------------------------------
	-- Extract parameter definitions (if any) into temp table
	---------------------------------------------------
	
	CREATE TABLE #TPD (
		[Section] Varchar(128),
		[Name] Varchar(128),
		[Value] Varchar(max) NULL,
		[Reqd] Varchar(32) NULL
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
	-- Extract input parameters into temp table
	---------------------------------------------------
	--
	CREATE TABLE #TJP (
		[Section] Varchar(128),
		[Name] Varchar(128),
		[Value] Varchar(max)
	)

	Declare @jobParamXML XML
	Set @jobParamXML = CONVERT(XML, @jobParam)
	
	INSERT INTO #TJP ([Section], [Name], [Value])	
	SELECT
		xmlNode.value('@Section', 'nvarchar(256)') Section,
		xmlNode.value('@Name', 'nvarchar(256)') Name,
		xmlNode.value('@Value', 'nvarchar(4000)') Value
	FROM
		@jobParamXML.nodes('//Param') AS R(xmlNode)

	---------------------------------------------------
	-- Cross check to make sure required parameters are defined in #TJP (populated using @paramInput)
	---------------------------------------------------
    --
	Declare @s varchar(8000) = ''

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
		Set @message = 'Missing required parameters:' + @s
		Set @myError = 50101
		Print @message
		return @myError
	END

	---------------------------------------------------
	-- Cross check to make sure required parameters are defined in #TJP (populated using @paramInput)
	---------------------------------------------------
    --	
    If @scriptName LIKE 'MaxQuant%' Or @scriptName LIKE 'MSFragger%'
    Begin
        -- Verify the MaxQuant or MSFragger parameter file name
        -- Also verify the protein collection (or legacy FASTA file)
        -- For protein collections, will auto-add contaminants if needed

        If @scriptName Like 'MaxQuant%'
            Set @scriptBaseName = 'MaxQuant'
        Else
            Set @scriptBaseName = 'MSFragger'

        SELECT @parameterFileName = Value
        FROM #TJP
        WHERE Name = 'ParmFileName'
        --
	    SELECT @myError = @@error, @myRowCount = @@rowcount

        SELECT @protCollNameList = Value
        FROM #TJP
        WHERE Name = 'ProteinCollectionList'

        SELECT @protCollOptionsList = Value
        FROM #TJP
        WHERE Name = 'ProteinOptions'
        
        SELECT @organismName = Value
        FROM #TJP
        WHERE Name = 'OrganismName'

        SELECT @organismDBName = Value
        FROM #TJP
        WHERE Name = 'LegacyFastaFileName'

        Set @protCollNameList = LTrim(RTrim(IsNull(@protCollNameList, '')))
        
        If ISNULL(@protCollOptionsList, '') = ''
        Begin
            If @scriptBaseName = 'MaxQuant'
                Set @protCollOptionsList = 'seq_direction=forward,filetype=fasta'
            Else
                Set @protCollOptionsList = 'seq_direction=decoy,filetype=fasta'
        End

        If @scriptBaseName = 'MaxQuant' And @protCollOptionsList <> 'seq_direction=forward,filetype=fasta'
        Begin
            Set @message = 'The ProteinOptions parameter must be "seq_direction=forward,filetype=fasta" for MaxQuant jobs'
		    Set @myError = 50102
		    Print @message
		    return @myError
        End

        If @scriptBaseName = 'MSFragger' And @protCollOptionsList <> 'seq_direction=decoy,filetype=fasta'
        Begin
            Set @message = 'The ProteinOptions parameter must be "seq_direction=decoy,filetype=fasta" for MSFragger jobs'
		    Set @myError = 50103
		    Print @message
		    return @myError
        End
        
        SELECT @paramFileType = Param_File_Type, @paramFileValid = Valid
        FROM dbo.[S_DMS_V_Param_File_Export]
        WHERE Param_File_Name = @parameterFileName
        --
	    SELECT @myError = @@error, @myRowCount = @@rowcount

        If @myRowCount = 0
        Begin
            Set @message = 'Parameter file not found: ' + @parameterFileName
		    Set @myError = 50104
		    Print @message
		    return @myError
        End
        
        If @paramFileValid = 0
        Begin
            Set @message = 'Parameter file is not active: ' + @parameterFileName
		    Set @myError = 50105
		    Print @message
		    return @myError
        End
                
        If @paramFileType <> @scriptBaseName
        Begin
            Set @message = 'Parameter file is for ' + @paramFileType + ', and not ' + @scriptBaseName + ': ' + @parameterFileName
		    Set @myError = 50106
		    Print @message
		    return @myError
        End

        exec @myError = dbo.S_ValidateProteinCollectionParams
                        @scriptBaseName,
                        @organismDBName output,
                        @organismName,
                        @protCollNameList output,
                        @protCollOptionsList output,
                        @ownerPRN = '',
                        @message = @message output,
                        @debugMode = @debugMode

        If @myError = 0 AND Len(@protCollNameList) > 0 And dbo.ValidateNAParameter(@protCollNameList) <> 'na'
        Begin
            ---------------------------------------------------
            -- Validate @protCollNameList
            -- Note that ValidateProteinCollectionListForDatasetTable
            --  will populate @message with an explanatory note
            --  if @protCollNameList is updated
            ---------------------------------------------------
            --
            exec @myError = dbo.ValidateProteinCollectionListForDataPackage
                                @dataPackageID,
                                @protCollNameList=@protCollNameList output, 
                                @collectionCountAdded=@collectionCountAdded output, 
                                @showMessages=1, 
                                @message=@message output
        End

        If @myError = 0
        Begin
            -- Make sure values in #TJP are up-to-date, then re-generate @jobParamXML

            UPDATE #TJP
            SET Value = @protCollNameList
            WHERE Name = 'ProteinCollectionList'

            UPDATE #TJP
            SET Value = @protCollOptionsList
            WHERE Name = 'ProteinOptions'

            UPDATE #TJP
            SET Value = @organismName
            WHERE Name = 'OrganismName'

            UPDATE #TJP
            SET Value = @organismDBName
            WHERE Name = 'LegacyFastaFileName'

            Set @jobParamXML = ( SELECT * FROM #TJP AS Param FOR XML AUTO, TYPE)

            Set @jobParam = CAST(@jobParamXML as varchar(8000))
        End
    End

	return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[VerifyJobParameters] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[VerifyJobParameters] TO [Limited_Table_Write] AS [dbo]
GO
