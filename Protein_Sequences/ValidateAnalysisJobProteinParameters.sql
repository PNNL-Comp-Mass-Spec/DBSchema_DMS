/****** Object:  StoredProcedure [dbo].[ValidateAnalysisJobProteinParameters] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[ValidateAnalysisJobProteinParameters]
/****************************************************
**
**  Desc:
**      Validate the combination of organism DB file
**      (FASTA) file name, protein collection list,
**      and protein options list.
**
**      The protein collection list and protein options
**      list should be returned in canonical format.
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   kja
**  Date:   04/11/2006
**          06/06/2006 mem - Updated Creation Options List logic to allow wider range of @protCollOptionsList values
**          06/08/2006 mem - Added call to StandardizeProteinCollectionList to validate the order of @protCollNameList
**          06/26/2006 mem - Updated to ignore @organismDBFileName If @protCollNameList is <> 'na'
**          10/04/2007 mem - Expanded @protCollNameList from varchar(512) to varchar(max)
**                         - Expanded @organismName from varchar(64) to varchar(128)
**          01/12/2012 mem - Updated error message for error -50001
**          05/15/2012 mem - Updated error message for error -50001
**          09/25/2012 mem - Expanded @organismDBFileName to varchar(128)
**          06/24/2013 mem - Now removing duplicate protein collection names in @protCollNameList
**          07/27/2022 mem - Switch from FileName to Collection_Name in T_Protein_Collections
**          01/06/2023 mem - Use new column name in view
**
**  Error Return Codes:
**      (-50001) = both values cannot be blank or 'na'
**      (-50002) = ambiguous combination of legacy name and protein collection
**                 (different values for each)
**      (-50010) = General database retrieval error
**      (-50011) = Lookup keyword or value not valid
**      (-50020) = Encrypted collection authorization failure
**
*****************************************************/
(
    @organismName varchar(128),
    @ownerPRN varchar(30),
    @organismDBFileName varchar(128),
    @protCollNameList varchar(max) output,
    @protCollOptionsList varchar(256) output,
    @message varchar(512) output
)
As
    Set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Set @message = ''
    declare @msg varchar(256)

    -- Check for Null values
    Set @organismDBFileName = LTrim(RTrim(ISNULL(@organismDBFileName, '')))
    Set @protCollNameList = LTrim(RTrim(ISNULL(@protCollNameList, '')))
    Set @protCollOptionsList = LTrim(RTrim(ISNULL(@protCollOptionsList, '')))

    declare @legacyNameExists int
    Set @legacyNameExists = 0

    /****************************************************************
     ** Validate the input parameters
     ****************************************************************/

    If Len(@organismName) < 1
    Begin
        Set @msg = 'Org DB validation failure: Organism Name cannot be blank'
        Set @myError = -50001
        RAISERROR(@msg, 10, 1)
    End

    If Len(@organismDBFileName) < 1 and Len(@protCollNameList) > 0
    Begin
        Set @organismDBFileName = 'na'
        -- No error needed, just fix it
    End

    If Len(@protCollNameList) < 1 and Len(@organismDBFileName) > 0 and @organismDBFileName <> 'na'
    Begin
        Set @protCollNameList = 'na'
        -- No error needed, just fix it
    End

    If (Len(@organismDBFileName) = 0 and Len(@protCollNameList) = 0) OR (@organismDBFileName = 'na' AND @protCollNameList = 'na')
    Begin
        Set @msg = 'Org DB validation failure: Protein collection list and Legacy Fasta (OrgDBName) name cannot both be blank (or "na")'
        Set @myError = -50001
        RAISERROR(@msg, 10 ,1)
    End

    If @protCollNameList <> 'na' AND Len(@protCollNameList) > 0
    Begin
        Set @organismDBFileName = 'na'
        -- No error needed, just fix it
    End

    If @myError <> 0
    Begin
        Set @message = @msg
        return @myError
    End

    /****************************************************************
     ** Check Validity of Organism Name
     ****************************************************************/

    DECLARE @organism_ID int

    SELECT @organism_ID = ID
    FROM V_Organism_Picker
    WHERE Short_Name = @organismName

    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myError <> 0
    Begin
        Set @msg = 'Database retrieval error during organism name check (Protein_Sequences.V_Organism_Picker)'
        Set @myError = -50010
        Set @message = @msg
        RAISERROR (@msg, 10, 1)
        return @myError
    End

    If @myRowCount < 1
    Begin
        Set @msg = 'Organism "' + @organismName + '" does not exist (Protein_Sequences.V_Organism_Picker)'
        Set @myError = -50011
        Set @message = @msg
        RAISERROR (@msg, 10, 1)
        return @myError
    End


    /****************************************************************
     ** Check Validity of Legacy FASTA file name
     ****************************************************************/

    DECLARE @legacyFileID int

    If @organismDBFileName <> 'na' AND @protCollNameList = 'na'
    Begin -- <a1>
        If RIGHT(@organismDBFileName, 6) <> '.fasta'
            Set @organismDBFileName = @organismDBFileName + '.fasta'

        SELECT @legacyFileID = ID
        FROM V_Legacy_Static_File_Locations
        WHERE File_Name = @organismDBFileName

        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @myError <> 0
        Begin
            Set @msg = 'Database retrieval error during Organsim DB File name check (Protein_Sequences.V_Legacy_Static_File_Locations)'
            Set @myError = -50010
            Set @message = @msg
            RAISERROR (@msg, 10, 1)
            return @myError
        End

        If @myRowCount < 1
        Begin
            Set @msg = 'FASTA file "' + @organismDBFileName + '" does not exist (Protein_Sequences.V_Legacy_Static_File_Locations)'
            Set @myError = -50011
            Set @message = @msg
            RAISERROR (@msg, 10, 1)
            return @myError
        End
    End -- </a1>


    /****************************************************************
     ** Check Validity of Protein Collection Name List 
     ****************************************************************/

    If @protCollNameList <> 'na'
    Begin -- <a2>

        DECLARE @collListTable table(Collection_ID int Identity(1,1), Collection_Name varchar(128))

        INSERT INTO @collListTable (Collection_Name)
        SELECT DISTINCT LTrim(RTrim(Value))
        FROM dbo.udfParseDelimitedList(@protCollNameList, ',')

        DECLARE @cleanCollNameList varchar(max)
        Set @cleanCollNameList = ''

        DECLARE @currentCollectionName varchar(128)
        DECLARE @extensionPosition int
        DECLARE @currentCollectionID int

        DECLARE @loopCounter int = 0
        DECLARE @itemCounter int = 0

        declare @isEncrypted tinyint
        declare @isAuthorized tinyint

        SELECT @loopCounter = COUNT(*)
        FROM @collListTable

        While @loopCounter > 0
        Begin -- <b2>
            If @itemCounter > 0
            Begin
                Set @cleanCollNameList = @cleanCollNameList + ','
            End
            Set @loopCounter = @loopCounter - 1
            Set @itemCounter = @itemCounter + 1

            SELECT @currentCollectionName = Collection_Name
            FROM @collListTable
            WHERE Collection_ID = @itemCounter

            SELECT @myError = @@error, @myRowCount = @@rowcount

            Set @extensionPosition = CHARINDEX('.fasta', @currentCollectionName)
            If @extensionPosition > 0
            Begin
                Set @currentCollectionName = SUBSTRING(@currentCollectionName, 0, @extensionPosition)
            End

            SELECT @currentCollectionID = Protein_Collection_ID, @isEncrypted = Contents_Encrypted
            FROM T_Protein_Collections
            WHERE Collection_Name = @currentCollectionName

            SELECT @myError = @@error, @myRowCount = @@rowcount

            If @myError <> 0
            Begin
                Set @msg = 'Database retrieval error during collection name check (Protein_Sequences.T_Protein_Collections)'
                Set @message = @msg
                RAISERROR (@msg, 10, 1)
                return @myError
            End

            If @myRowCount = 0
            Begin
                Set @msg = '"' + @currentCollectionName + '" was not found in the Protein Collection List'
                Set @message = @msg
                RAISERROR (@msg, 10, 1)
                return -50001
            End

            If @isEncrypted > 0
            Begin -- <c2>
                SELECT Authorization_ID
                FROM T_Encrypted_Collection_Authorizations
                WHERE Login_Name LIKE '%' + @ownerPRN + '%' AND
                      Protein_Collection_ID = @currentCollectionID

                SELECT @myError = @@error, @myRowCount = @@rowcount

                If @myRowCount = 0
                Begin
                    Set @msg = @ownerPRN + ' is not authorized for the encrypted collection "' + @currentCollectionName + '"'
                    Set @message = @msg
                    RAISERROR (@msg, 10, 1)
                    return -50020
                End

            End -- </c2>

            Set @cleanCollNameList = @cleanCollNameList + @currentCollectionName
        End -- </b2>


        /****************************************************************
         ** Copy the data from @cleanCollNameList to @protCollNameList and
         ** validate the order of the entries
         ****************************************************************/

        Set @protCollNameList = @cleanCollNameList

        exec StandardizeProteinCollectionList @protCollNameList = @protCollNameList OUTPUT, @message = @message OUTPUT


        /****************************************************************
         ** Check Validity of Creation Options List
         ****************************************************************/

        DECLARE @tmpCommaPosition int = 0
        DECLARE @tmpStartPosition int = 0

        DECLARE @tmpOptionKeyword varchar(64)
        DECLARE @tmpOptionKeywordID int
        DECLARE @tmpOptionValueID int
        DECLARE @tmpOptionValue varchar(64)

        DECLARE @keywordDefaultValue varchar(64)
        DECLARE @keywordIsReqd tinyint

        DECLARE @tmpOptionString varchar(128)
        DECLARE @tmpOptionTable table(Keyword_ID int, Keyword varchar(64), Value varchar(64))

        DECLARE @tmpEqualsPosition int
        DECLARE @cleanOptionString varchar(256)
        Set @cleanOptionString = ''

        DECLARE @protCollOptionsListLength int
        Set @protCollOptionsListLength = Len(@protCollOptionsList)

        If @protCollOptionsListLength = 0
        Begin
            Set @protCollOptionsList = 'na'
            Set @protCollOptionsListLength = Len(@protCollOptionsList)
        End

        Set @tmpCommaPosition =  CHARINDEX(',', @protCollOptionsList)
        If @tmpCommaPosition = 0
        Begin
            Set    @tmpCommaPosition = @protCollOptionsListLength
        End


        While (@tmpCommaPosition <= @protCollOptionsListLength)
        Begin -- <b3>
            Set @tmpCommaPosition = CHARINDEX(',', @protCollOptionsList, @tmpStartPosition)
            If @tmpCommaPosition = 0
            Begin
                Set @tmpCommaPosition = @protCollOptionsListLength + 1
            End

            If @tmpCommaPosition > @tmpStartPosition
            Begin -- <c3>
                Set @tmpOptionString = LTRIM(SUBSTRING(@protCollOptionsList, @tmpStartPosition, @tmpCommaPosition - @tmpStartPosition))
                Set @tmpEqualsPosition = CHARINDEX('=', @tmpOptionString)

                If @tmpEqualsPosition = 0
                Begin
                    If @tmpOptionString <> 'na'
                    Begin
                        Set @msg = 'Keyword: "' + @tmpOptionString + '" not followed by an equals sign'
                        Set @message = @msg
                        return -50011
                    End
                End
                Else
                Begin -- <d3>
                    Set @tmpOptionKeyword = LEFT(@tmpOptionString, @tmpEqualsPosition - 1)
                    Set @tmpOptionValue = RIGHT(@tmpOptionString, Len(@tmpOptionString) - @tmpEqualsPosition)

                    -- Auto-update seq_direction 'reverse' to 'reversed'
                    If @tmpOptionKeyword = 'seq_direction' and @tmpOptionValue = 'reverse'
                        Set @tmpOptionValue = 'reversed'

                    -- Look for @tmpOptionKeyword in T_Creation_Option_Keywords
                    SELECT @tmpOptionKeywordID = Keyword_ID
                    FROM T_Creation_Option_Keywords
                    WHERE Keyword = @tmpOptionKeyword

                    SELECT @myError = @@error, @myRowCount = @@rowcount

                    If @myError = 0 and @myRowCount > 0
                    Begin
                        INSERT INTO @tmpOptionTable (Keyword_ID, Keyword, Value)
                        VALUES (@tmpOptionKeywordID, @tmpOptionKeyword, @tmpOptionValue)
                    End

                    If @myError > 0
                    Begin
                        Set @msg = 'Database retrieval error during keyword validity check'
                        Set @message = @msg
                        return @myError
                    End

                    If @myRowCount = 0
                    Begin
                        Set @msg = 'Keyword: "' + @tmpOptionKeyword + '" not located'
                        Set @message = @msg
                        return -50011
                    End
                End -- </d3>
            End -- </c3>

            Set @tmpStartPosition = @tmpCommaPosition + 1
        End -- </b3>


        -- Cruise through collected Keyword/Value Pairs and check for validity
        Declare @KeywordID int
        Set @KeywordID = 0

        Declare @continue tinyint

        Set @continue = 1
        While @continue = 1
        Begin -- <b4>
            SELECT    TOP 1
                    @KeywordID = Keyword_ID,
                    @tmpOptionKeyword = Keyword,
                    @keywordDefaultValue = Default_Value,
                    @keywordIsReqd = IsRequired
            FROM T_Creation_Option_Keywords
            WHERE Keyword_ID > @KeywordID
            ORDER BY Keyword_ID
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount

            If @myRowCount = 0
                Set @continue = 0
            Else
            Begin -- <c4>
                If Len(@cleanOptionString) > 0
                    Set @cleanOptionString = @cleanOptionString + ','

                --Check Specified Value Existence
                SELECT @tmpOptionValue = Value
                FROM @tmpOptionTable
                WHERE Keyword = @tmpOptionKeyword
                --
                SELECT @myError = @@error, @myRowCount = @@rowcount

                If @myError = 0 and @myRowCount > 0
                Begin -- <d4>
                    -- Validate @tmpOptionValue against T_Creation_Option_Values
                    SELECT @tmpOptionValue = OptValues.Value_String
                    FROM T_Creation_Option_Values OptValues INNER JOIN
                            T_Creation_Option_Keywords OptKeywords ON OptValues.Keyword_ID = OptKeywords.Keyword_ID
                    WHERE OptKeywords.Keyword = @tmpOptionKeyword AND
                            OptValues.Value_String = @tmpOptionValue
                    --
                    SELECT @myError = @@error, @myRowCount = @@rowcount

                    If @myError = 0 and @myRowCount > 0
                        Set @cleanOptionString = @cleanOptionString + @tmpOptionKeyword + '=' + @tmpOptionValue

                End-- </d4>

                If @myError <> 0
                Begin
                    Set @msg = 'Database retrieval error during keyword validity check'
                    Set @message = @msg
                    return @myError
                End

                If @myRowCount = 0 and @keywordIsReqd > 0
                    Set @cleanOptionString = @cleanOptionString + @tmpOptionKeyword + '=' + @keywordDefaultValue

            End -- </c4>
        End -- <b4>

        Set @protCollOptionsList = @cleanOptionString
    End -- </a2>

    return @myError


GO
GRANT EXECUTE ON [dbo].[ValidateAnalysisJobProteinParameters] TO [DMS_Analysis] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[ValidateAnalysisJobProteinParameters] TO [DMS_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[ValidateAnalysisJobProteinParameters] TO [PROTEINSEQS\ProteinSeqs_Upload_Users] AS [dbo]
GO
