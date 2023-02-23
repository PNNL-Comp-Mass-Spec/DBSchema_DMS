/****** Object:  StoredProcedure [dbo].[StoreParamFileMassMods] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[StoreParamFileMassMods]
/****************************************************
**
**  Stores (or validates) the dynamic and static mods to associate with a given parameter file
**
**  Format for MS-GF+, MSPathFinder, and mzRefinery:
**     The mod names listed in the 5th comma-separated column must be UniMod names 
**     and must match the Original_Source_Name values in T_Mass_Correction_Factors
**
**     StaticMod=144.102063,  *,  fix, N-term,    iTRAQ4plex           # 4-plex iTraq
**     StaticMod=144.102063,  K,  fix, any,       iTRAQ4plex           # 4-plex iTraq
**     StaticMod=C2H3N1O1,    C,  fix, any,       Carbamidomethyl      # Fixed Carbamidomethyl C (alkylation)
**
**     DynamicMod=HO3P, STY, opt, any,            Phospho              # Phosphorylation STY
**
**  Format for DIA-NN:
**     The format is Mod Name, Mass, Residues
**     The Mod Name in the first column should be in the form UniMod:35
**     If the mod does not have a UniMod ID, any name can be used, but @validateUnimod must then be set to 0 when calling this procedure
**     The residue list can include 'n' for the peptide N-terminus or '*n' for the protein N-terminus
**
**     StaticMod=UniMod:737,   229.162933, n         # TMT6plex
**     StaticMod=UniMod:737,   229.162933, K         # TMT6plex
**     StaticMod=UniMod:2016,  304.207153, n         # TMT16plex (TMTpro)
**     StaticMod=UniMod:2016,  304.207153, K         # TMT16plex
**
**     DynamicMod=UniMod:35,   15.994915,  M         # Oxidized methionine
**     DynamicMod=UniMod:21,   79.966331,  STY       # Phosphorylated STY
**     DynamicMod=UniMod:1,    42.010565,  *n        # Acetylation protein N-term
**     DynamicMod=UniMod:34,   14.015650,  n         # N-terminal methylation
**     DynamicMod=UniMod:121,  114.042927, K         # Lysine ubiquitinylation (K-GG)
**
**     Note that Static +57.021 on cysteine (carbamidomethylation) should be enabled using 
**     StaticCysCarbamidomethyl=True (which corresponds to command line argument --unimod4)
**
**  Format for TopPIC:
**     The format is UniMod Name, Mass, Residues, Position, UnimodID
**     The UnimodName in the first column should match the Original_Source_Name values in T_Mass_Correction_Factors
**
**     StaticMod=Carbamidomethylation,57.021464,C,any,4
**     StaticMod=TMT6plex,229.1629,*,N-term,737
**     StaticMod=TMT6plex,229.1629,K,any,737
**
**     DynamicMod=Phospho,79.966331,STY,any,21
**     DynamicMod=Oxidation,15.994915,CMW,any,35
**     DynamicMod=Methyl,14.015650,*,N-term,34
**
**  Format for MSFragger:
**     variable_mod_01 = 15.994900 M 3        # Oxidized methionine
**     variable_mod_02 = 42.010600 [^ 1       # Acetylation protein N-term
**     variable_mod_06 = 304.207146 n^ 1      # 16-plex TMT
**     add_C_cysteine = 57.021464
**     add_K_lysine = 304.207146              # 16-plex TMT
**
**  Format for MaxQuant when the run type is "Standard":
**     <fixedModifications>
**        <string>Carbamidomethyl (C)</string>
**     </fixedModifications>
**     <variableModifications>
**        <string>Oxidation (M)</string>
**        <string>Acetyl (Protein N-term)</string>
**     </variableModifications>
**
**  Format for MaxQuant when the run type is "Reporter ion MS2":
**     <fixedModifications>
**        <string>Carbamidomethyl (C)</string>
**     </fixedModifications>
**     <variableModifications>
**        <string>Oxidation (M)</string>
**        <string>Acetyl (Protein N-term)</string>
**     </variableModifications>
**     <isobaricLabels>
**        <IsobaricLabelInfo>
**           <internalLabel>TMT6plex-Lys126</internalLabel>
**           <terminalLabel>TMT6plex-Nter126</terminalLabel>
**        </IsobaricLabelInfo>
**     </isobaricLabels>
**
**
**  To validate mods without storing them, set @paramFileID to 0 or a negative number
**
**  Auth:   mem
**  Date:   05/16/2013 mem - Initial version
**          06/04/2013 mem - Now replacing tab characters with spaces
**          09/16/2013 mem - Now allowing mod Heme_615 to be stored (even though it is from PNNL and not UniMod)
**          09/03/2014 mem - Now treating static N-term or C-term mods that specify a target residue (instead of *) as Dynamic mods (a requirement for PHRP)
**          10/02/2014 mem - Add exception for Dyn2DZ
**          05/26/2015 mem - Add @validateUnimod
**          12/01/2015 mem - Now showing column Residue_Desc
**          03/14/2016 mem - Look for an entry in column Mass_Correction_Tag of T_Mass_Correction_Factors if no match is found in Original_Source_Name and @validateUnimod = 0
**          08/31/2016 mem - Fix logic parsing N- or C-terminal static mods that use * for the affected residue
**                         - Store static N- or C-terminal mods as type 'T' instead of 'S'
**          11/30/2016 mem - Check for a residue specification of any instead of *
**          12/12/2016 mem - Check for tabs in the comma-separated mod definition rows
**          12/13/2016 mem - Silently skip rows StaticMod=None and DynamicMod=None
**          10/02/2017 mem - If @paramFileID is 0 or negative, validate mods only.  Returns 0 if valid, error code if not valid
**          08/17/2018 mem - Add support for TopPIC mods
**                           Add parameter @paramFileType
**          11/19/2018 mem - Pass 0 to the @maxRows parameter to udfParseDelimitedListOrdered
**          04/23/2019 mem - Add support for MSFragger mod defs
**          03/05/2021 mem - Add support for MaxQuant mod defs
**          05/13/2021 mem - Fix handling of static MaxQuant mods that are N-terminal or C-terminal 
**          05/18/2021 mem - Add support for reporter ions in MaxQuant mod defs
**          06/15/2021 mem - Remove UNION statements to avoid sorting
**                         - Collapse isobaric mods into a single entry
**          09/07/2021 mem - Add support for dynamic N-terminal TMT mods in MSFragger (notated with n^)
**          02/23/2023 mem - Add support for DIA-NN
**    
*****************************************************/
(
    @paramFileID int,            -- If 0 or a negative number, will validate the mods without updating any tables
    @mods varchar(max),
    @infoOnly tinyint = 0,       -- 1 to print @row, 2 to show #Tmp_Residues for each modification
    @replaceExisting tinyint = 0,
    @validateUnimod tinyint = 1,
    @paramFileType varchar(50) = '',    -- MSGFDB, DIA-NN, TopPIC, MSFragger, or MaxQuant; if empty, will lookup using @paramFileID; if no match (or if @paramFileID is null or 0) assumes MSGFDB (aka MS-GF+)
    @message varchar(512) = '' OUTPUT
)
AS
    Set NoCount On

    Declare @myRowCount int = 0
    Declare @myError int = 0

    Declare @msgAddon varchar(512)
    Declare @paramFileName varchar(255)

    Declare @validateOnly tinyint = 0
    Declare @tempTablesCreated tinyint = 0
    
    Declare @paramFileTypeID int = 0
        
    -----------------------------------------
    -- Validate the input parameters
    -----------------------------------------
    
    Set @infoOnly = IsNull(@infoOnly, 0)
    Set @replaceExisting = IsNull(@replaceExisting, 0)
    Set @validateUnimod = IsNull(@validateUnimod, 1)
    Set @paramFileType = Ltrim(Rtrim(IsNull(@paramFileType, '')))

    Set @message = ''
    
    If @paramFileID Is Null 
    Begin
        Set @message = 'The Parameter file ID must be defined; unable to continue'
        Set @myError = 53000
        Goto Done
    End

    If IsNull(@mods, '') = ''
    Begin
        Set @message = 'The Mods to parse cannot be empty; unable to continue'
        Set @myError = 53001
        Goto Done
    End

    If @paramFileID <= 0
    Begin
        Set @validateOnly = 1
        If @paramFileType = ''
        Begin
            Set @paramFileType = 'MSGFDB'
        End
    End
    Else
    Begin
        -----------------------------------------
        -- Make sure the parameter file ID is valid
        -----------------------------------------
        
        Set @paramFileName = ''
        Set @paramFileTypeID = 0

        SELECT @paramFileName = Param_File_Name, @paramFileTypeID = Param_File_Type_ID
        FROM T_Param_Files
        WHERE Param_File_ID = @paramFileID
        
        If IsNull(@paramFileName, '') = ''
        Begin
            Set @message = 'Param File ID (' + Convert(varchar(12), @paramFileID) + ') not found in T_Param_Files; unable to continue'
            Set @myError = 53002
            Goto Done
        End
        
        If @replaceExisting = 0 And Exists (SELECT * FROM T_Param_File_Mass_Mods WHERE Param_File_ID = @paramFileID)
        Begin
            Set @message = 'Param File ID (' + Convert(varchar(12), @paramFileID) + ') has existing mods in T_Param_File_Mass_Mods but @replaceExisting = 0; unable to continue'
            Set @myError = 53003
            Goto Done
        End

        If @paramFileTypeID > 0
        Begin
            Declare @paramFileTypeNew varchar(50)=''

            Select @paramFileTypeNew = Param_File_Type
            From T_Param_File_Types
            Where Param_File_Type_ID = @paramFileTypeID

            If IsNull(@paramFileTypeNew, '') <> ''
            Begin
                Set @paramFileType = @paramFileTypeNew
            End
        End
    End
    
    If Not @paramFileType In ('MSGFDB', 'DIA-NN', 'TopPIC', 'MSFragger', 'MaxQuant')
    Begin
        Set @paramFileType = 'MSGFDB'
    End

    -----------------------------------------
    -- Create some temporary tables
    -----------------------------------------

    CREATE TABLE #Tmp_MaxQuant_Mods (
        EntryID int NOT NULL IDENTITY(1,1),
        ModType varchar(24) NOT NULL,
        ModName varchar(128) NULL
    )
    
    CREATE UNIQUE CLUSTERED INDEX #IX_Tmp_MaxQuant_Mods ON #Tmp_MaxQuant_Mods (EntryID)
    
    CREATE TABLE #Tmp_Mods (
        EntryID int NOT NULL,
        Value varchar(2048) null
    )
    
    CREATE UNIQUE CLUSTERED INDEX #IX_Tmp_Mods ON #Tmp_Mods (EntryID)
    
    CREATE TABLE #Tmp_ModDef (
        EntryID int NOT NULL,
        Value varchar(2048) null
    )
    
    CREATE UNIQUE CLUSTERED INDEX #IX_Tmp_ModDef ON #Tmp_ModDef (EntryID)

    CREATE TABLE #Tmp_Residues (
        Residue_Symbol char NOT NULL,
        Residue_ID int NULL,
        Residue_Desc varchar(64) NULL,
        Terminal_AnyAA tinyint NULL        -- Set to 1 when making any residue at a a peptide or protein N- or C-terminus; 0 if matching specific residues at terminii
    )
    
    CREATE UNIQUE CLUSTERED INDEX #IX_Tmp_Residues ON #Tmp_Residues (Residue_Symbol)
        
    CREATE TABLE #Tmp_ModsToStore (
        Entry_ID int Identity(1,1),
        Mod_Name varchar(255),
        Mass_Correction_ID int NOT NULL,
        Mod_Type_Symbol varchar(1) NULL,
        Residue_Symbol varchar(12) NULL,
        Residue_ID int NULL,
        Local_Symbol_ID int NULL,
        Residue_Desc varchar(64) Null,
        Monoisotopic_Mass float NULL,
        MaxQuant_Mod_ID int Null,
        Isobaric_Mod_Ion_Number Int Null
    )
    
    CREATE UNIQUE CLUSTERED INDEX #IX_Tmp_ModsToStore ON #Tmp_ModsToStore (Entry_ID)
    
    Set @tempTablesCreated = 1
    
    -----------------------------------------
    -- Split @mods on carriage returns (or line feeds)
    -- Store the data in #Tmp_Mods
    -----------------------------------------

    Declare @delimiter varchar(1) = ''

    If @paramFileType = 'MaxQuant'
    Begin
        -- Parse the text as XML
        DECLARE @xml XML = @mods
     
        -- Look for defined modifications
        -- Do not use a UNION statement here, since sort order is lost

        INSERT INTO #Tmp_MaxQuant_Mods (ModType, ModName)
        SELECT 'fixed' as ModType,
               Mods.ModInfo.value('.', 'varchar(128)')
        FROM   @xml.nodes('/fixedModifications/string') AS Mods(ModInfo)
        
        INSERT INTO #Tmp_MaxQuant_Mods (ModType, ModName)
        SELECT 'fixed' as ModType,
               Mods.ModInfo.value('.', 'varchar(128)')
        FROM   @xml.nodes('/MaxQuantParams/parameterGroups/parameterGroup/fixedModifications/string') AS Mods(ModInfo)
        
        INSERT INTO #Tmp_MaxQuant_Mods (ModType, ModName)
        SELECT 'variable' as ModType,
               Mods.ModInfo.value('.', 'varchar(128)')
        FROM   @xml.nodes('/variableModifications/string') AS Mods(ModInfo)
        
        INSERT INTO #Tmp_MaxQuant_Mods (ModType, ModName)
        SELECT 'variable' as ModType,
               Mods.ModInfo.value('.', 'varchar(128)')
        FROM   @xml.nodes('/MaxQuantParams/parameterGroups/parameterGroup/variableModifications/string') AS Mods(ModInfo)

        If CharIndex('IsobaricLabelInfo', @mods) > 0
        Begin
            -- Reporter ions are defined (e.g. TMT or iTRAQ)
            -- Treat these as fixed mods
            INSERT INTO #Tmp_MaxQuant_Mods (ModType, ModName)
            SELECT 'fixed' as ModType,
                   Mods.ModInfo.value('.', 'varchar(128)')
            FROM   @xml.nodes('/isobaricLabels/IsobaricLabelInfo/internalLabel') AS Mods(ModInfo)
            UNION
            SELECT 'fixed' as ModType,
                   Mods.ModInfo.value('.', 'varchar(128)')
            FROM   @xml.nodes('/isobaricLabels/IsobaricLabelInfo/terminalLabel') AS Mods(ModInfo)
        End

        If Not Exists (SELECT * FROM #Tmp_MaxQuant_Mods)
        Begin
            Set @message = 'Did not find any XML nodes matching <fixedModifications> <string></string> </fixedModifications> or <variableModifications> <string></string> </variableModifications>'
            Set @myError = 53004
            Goto Done
        End

        -- Populate the Tmp_Mods table with entries of the form:
        --   fixed=Carbamidomethyl (C)
        --   variable=Oxidation (M)

        INSERT INTO #Tmp_Mods (EntryID, Value)
        SELECT EntryID, ModType + '=' + ModName
        FROM #Tmp_MaxQuant_Mods
        ORDER BY EntryID
        --
        SELECT @myRowCount = @@rowcount, @myError = @@error
    End
    Else
    Begin
        If CHARINDEX(CHAR(10), @mods) > 0
            Set @delimiter = CHAR(10)
        Else
            Set @delimiter = CHAR(13)
    
        INSERT INTO #Tmp_Mods (EntryID, Value)
        SELECT EntryID, Value
        FROM dbo.udfParseDelimitedListOrdered(@mods, @delimiter, 0)
        --
        SELECT @myRowCount = @@rowcount, @myError = @@error
        
        If Not Exists (SELECT * FROM #Tmp_Mods)
        Begin
            Set @message = 'Nothing returned when splitting the Mods on CR or LF'
            Set @myError = 53004
            Goto Done
        End
    End

    If @infoOnly > 0
    Begin
        Select * From #Tmp_Mods
    End

    Declare @entryID int = 0
    Declare @entryIDEnd int = 0

    Declare @charIndex int
    Declare @rowCount int
    Declare @validRow Tinyint
    
    Declare @row varchar(2048)
    Declare @rowKey varchar(1000)
    Declare @rowValue varchar(2048)
    Declare @rowParsed tinyint

    Declare @field varchar(512)
    Declare @affectedResidues varchar(512)
        
    Declare @modType varchar(128)
    Declare @modTypeSymbol varchar(1)
    Declare @massCorrectionID int

    Declare @modTypeSymbolToStore varchar(1)
    
    Declare @modName varchar(255)
    Declare @modMass float
    Declare @modMassToFind float
    Declare @location varchar(128)
    Declare @isobaricModIonNumber int

    Declare @lookupUniModID tinyint
    Declare @staticCysCarbamidomethyl tinyint

    Declare @uniModIDText varchar(20)
    Declare @uniModID int

    Declare @maxQuantModID int

    Declare @localSymbolID int = 0
    Declare @localSymbolIDToStore int
    
    Declare @terminalMod tinyint
    Declare @residueSymbol varchar(1)
    
    SELECT @entryIDEnd = MAX(EntryID)
    FROM #Tmp_Mods
    
    -----------------------------------------
    -- Parse the modification definitions
    -----------------------------------------
    --

    Set @entryID = 0

    While @entryID < @entryIDEnd
    Begin
        SELECT TOP 1 @entryID = EntryID, @row = Value
        FROM #Tmp_Mods
        WHERE EntryID > @entryID
        ORDER BY EntryID
        --
        SELECT @myRowCount = @@rowcount, @myError = @@error
        
        -- @row should now be empty, or contain something like the following:

        -- For MS-GF+
        -- StaticMod=144.102063,  *,  fix, N-term,    iTRAQ4plex         # 4-plex iTraq
        --   or
        -- DynamicMod=HO3P, STY, opt, any,            Phospho            # Phosphorylation STY

        -- For DIA-NN
        -- StaticMod=UniMod:737,   229.1629,   n         # TMT6plex
        --   or
        -- DynamicMod=UniMod:35,   15.994915,  M         # Oxidized methionine
        
        -- For TopPIC: 
        -- StaticMod=Carbamidomethylation,57.021464,C,any,4
        --   or 
        -- DynamicMod=Phospho,79.966331,STY,any,21

        -- For MSFragger:
        -- variable_mod_01 = 15.9949 M
        --   or
        -- add_C_cysteine = 57.021464             # added to C - avg. 103.1429, mono. 103.00918

        -- For MaxQuant:
        -- variable=Oxidation (M)
        --   or
        -- fixed=Carbamidomethyl (C)
        
        -- Remove any text after the comment character, #
        Set @charIndex = CharIndex('#', @row)
        If @charIndex > 0
            Set @row = SubString(@row, 1, @charIndex-1)
        
        -- Remove unwanted whitespace characters
        Set @row = Replace (@row, CHAR(10), '')
        Set @row = Replace (@row, CHAR(13), '')
        Set @row = Replace (@row, CHAR(9), ' ')
        Set @row = LTrim(RTrim(IsNull(@row, '')))
        
        If @row <> ''
        Begin
            If @infoOnly > 0
                Print @row

            DELETE FROM #Tmp_ModDef
            Set @rowParsed = 0

            If @paramFileType = 'MSFragger'
            Begin
                Set @rowParsed = 1;

                If @row Like 'variable[_]mod%'
                Begin
                    Set @charIndex = CharIndex('=', @row)
                    If @charIndex > 0
                    Begin
                        Set @rowValue = Ltrim(Rtrim(Substring(@row, @charIndex+1, Len(@row))))

                        INSERT INTO #Tmp_ModDef (EntryID, Value)
                        SELECT EntryID, Value
                        FROM dbo.udfParseDelimitedListOrdered(@rowValue, ' ', 0)

                        Update #Tmp_ModDef 
                        Set Value = 'DynamicMod=' + Value
                        Where EntryID = 1
                    End
                End

                If @row Like 'add[_]%'
                Begin
                    Set @charIndex = CharIndex('=', @row)
                    If @charIndex > 0
                    Begin
                        Set @rowKey = Ltrim(Rtrim(Substring(@row, 1, @charIndex-1)))
                        Set @rowValue = Ltrim(Rtrim(Substring(@row, @charIndex+1, Len(@row))))

                        INSERT INTO #Tmp_ModDef (EntryID, Value)
                        SELECT EntryID, Value
                        FROM dbo.udfParseDelimitedListOrdered(@rowValue, ' ', 0)

                        Update #Tmp_ModDef 
                        Set Value = 'StaticMod=' + Value
                        Where EntryID = 1

                        -- @rowKey is similar to add_C_cysteine or add_Cterm_peptide
                        -- Remove "add_"
                        Set @rowKey = Substring(@rowKey, 5, 100)

                        -- Add the affected mod symbol as the second column
                        If @rowKey Like 'Nterm[_]peptide%'
                        Begin
                            Set @residueSymbol = '<'
                        End
                        Else If @rowKey Like 'Cterm[_]peptide%'
                        Begin
                            Set @residueSymbol = '>'
                        End 
                        Else If @rowKey Like 'Nterm[_]protein%'
                        Begin
                            Set @residueSymbol = '['
                        End
                        Else If @rowKey Like 'Cterm[_]protein%'
                        Begin
                            Set @residueSymbol = ']'
                        End 
                        Else
                        Begin
                            -- @rowKey is similar to C_cysteine
                            Set @residueSymbol = Substring(@rowKey, 1, 1)
                        End

                        If Exists (Select * From #Tmp_ModDef Where EntryID = 2)
                        Begin
                            Update #Tmp_ModDef 
                            Set Value = @residueSymbol
                            Where EntryID = 2
                        End
                        Else
                        Begin
                            Insert Into #Tmp_ModDef (EntryID, Value)
                            Values (2, @residueSymbol)
                        End
                    End
                End

            End

            If @paramFileType = 'MaxQuant'
            Begin
                Set @rowParsed = 1;
                
                If @row Like 'variable=%'
                Begin
                    Set @charIndex = CharIndex('=', @row)
                    Set @rowValue = Ltrim(Rtrim(Substring(@row, @charIndex+1, Len(@row))))

                    INSERT INTO #Tmp_ModDef (EntryID, Value)
                    VALUES (1, 'DynamicMod=' + @rowValue)
                End

                If @row Like 'fixed=%'
                Begin
                    Set @charIndex = CharIndex('=', @row)
                    Set @rowValue = Ltrim(Rtrim(Substring(@row, @charIndex+1, Len(@row))))

                    INSERT INTO #Tmp_ModDef (EntryID, Value)
                    VALUES (1, 'StaticMod=' + @rowValue)
                End
            End

            If @paramFileType = 'DIA-NN'
            Begin
                -- Check for setting StaticCysCarbamidomethyl=True
                If @row Like 'StaticCysCarbamidomethyl%=%True'
                Begin
                    Set @rowParsed = 1;

                    -- Store this as a StaticMod entry, using the keyword StaticCysCarbamidomethyl
                    INSERT INTO #Tmp_ModDef (EntryID, Value)
                    VALUES (1, 'StaticMod=StaticCysCarbamidomethyl'),
                           (2, '57.021465'),
                           (3, 'C')
                End
            End

            If @rowParsed = 0
            Begin
                -- MS-GF+ style mod (also used by DIA-NN and TOPIC)
                INSERT INTO #Tmp_ModDef (EntryID, Value)
                SELECT EntryID, Value
                FROM dbo.udfParseDelimitedListOrdered(@row, ',', 0)
            End

            If Not Exists (SELECT * FROM #Tmp_ModDef)
            Begin
                Print 'Skipping row since #Tmp_ModDef is empty: ' + @row
            End
            Else
            Begin
                -----------------------------------------
                -- Look for an equals sign in the first entry of #Tmp_ModDef
                -----------------------------------------
                --
                Set @field = ''
                SELECT @field = LTrim(RTrim(Value))
                FROM #Tmp_ModDef
                WHERE EntryID = 1
                
                -- @field should now look something like the following:
                -- StaticMod=None
                -- DynamicMod=None
                -- DynamicMod=O1
                -- DynamicMod=15.9949
                -- DynamicMod=Oxidation (M)
                --
                -- Look for an equals sign in @field
                
                Set @charIndex = CharIndex('=', @field)
                
                If @charIndex <= 1
                Begin
                    Print 'Skipping row since first column does not contain an equals sign: ' + @row
                End
                Else
                Begin
                    -----------------------------------------
                    -- Determine the ModType
                    -----------------------------------------
                    --
                    Set @modType = SubString(@field, 1, @charIndex-1)
                    If @modType Not In ('DynamicMod', 'StaticMod')
                    Begin
                        Print 'Skipping row since setting is not a DynamicMod or StaticMod setting: ' + @row
                    End
                    Else
                    Begin
                        -- Now that the @modType is known, remove that text from the first field in #Tmp_ModDef
                        --
                        Update #Tmp_ModDef
                        Set Value = Substring(Value, @charIndex+1, 2048)
                        Where EntryID = 1

                        -- Assure that #Tmp_ModDef has at least 5 rows for MS-GF+ or TopPIC
                        -- For DIA-NN, require at least 3 rows
                        -- For MSFragger, require at least 2 rows
                        -- For MaxQuant, there will just be 1 row, which has the MaxQuant-tracked mod name
                        --
                        SELECT @rowCount = COUNT(*)
                        FROM #Tmp_ModDef
                
                        Set @validRow = 1

                        If @paramFileType In ('MSGFDB', 'TopPIC') And @rowCount < 5
                        Begin
                            Set @validRow = 0

                            If CharIndex(Char(9), @row) > 0
                            Begin
                                If CharIndex(',', @row) > 0
                                    Set @message = 'Aborting since row has a mix of tabs and commas; should only be comma-separated: ' + @row
                                Else
                                    Set @message = 'Aborting since row appears to be tab separated instead of comma-separated: ' + @row
                                    
                                Set @myError = 53011
                                If @infoOnly = 0
                                    Goto Done
                            End
                            Else
                            Begin
                                -- MS-GF+ uses 'StaticMod=None' and 'DynamicMod=None' to indicate no static or dynamic mods
                                -- TopPIC uses 'StaticMod=None' and 'DynamicMod=Defaults' to indicate no static or dynamic mods
                                If Not @field in ('StaticMod=None', 'DynamicMod=None', 'DynamicMod=Defaults')
                                Begin
                                    Set @message = 'Aborting since ' + @paramFileType + ' row has ' + Cast(@rowCount as varchar(4)) + ' comma-separated columns (should have 5 columns): ' + @row
                                    Set @myError = 53012
                                    
                                    If @infoOnly = 0
                                        Goto Done
                                End
                            End                            
                        End
                        
                        If @paramFileType In ('DIA-NN') And @rowCount < 3
                        Begin
                            Set @validRow = 0
                            Print 'Skipping row since not enough rows in #Tmp_ModDef: ' + @row
                        End

                        If @paramFileType In ('MSFragger') And @rowCount < 2
                        Begin
                            Set @validRow = 0
                            Print 'Skipping row since not enough rows in #Tmp_ModDef: ' + @row
                        End

                        If @validRow > 0
                        Begin

                            Set @field = ''

                            If @paramFileType In ('DIA-NN', 'TopPIC', 'MSFragger', 'MaxQuant')
                            Begin
                                -- Mod defs for these tools don't include 'opt' or 'fix, so we update @field based on @modType
                                If @modType = 'DynamicMod'
                                    Set @field = 'opt'
                                If @modType = 'StaticMod'
                                    Set @field = 'fix'
                            End
                            Else
                            Begin
                                -- MS-GF+
                                SELECT @field = LTrim(RTrim(Value))
                                FROM #Tmp_ModDef
                                WHERE EntryID = 3
                            End
                            
                            If @modType = 'DynamicMod'
                            Begin
                                Set @modTypeSymbol = 'D'
                                If @field <> 'opt'
                                Begin
                                    Set @message = 'DynamicMod entries must have "opt" in the 3rd column; aborting; see row: ' + @row
                                    Set @myError = 53005
                                    Goto Done
                                End
                                
                            End
                            
                            If @modType = 'StaticMod'
                            Begin
                                Set @modTypeSymbol = 'S'
                                If @field <> 'fix'
                                Begin
                                    Set @message = 'StaticMod entries must have "fix" in the 3rd column; aborting; see row: ' + @row
                                    Set @myError = 53006
                                    Goto Done
                                End
                            End

                            Set @modName = ''
                            Set @modMass = 0
                            Set @modMassToFind = 0
                            Set @massCorrectionID = 0
                            Set @location = ''
                            Set @terminalMod = 0
                            Set @affectedResidues = ''
                            Set @maxQuantModID = NULL
                            Set @isobaricModIonNumber = 0

                            DELETE FROM #Tmp_Residues

                            If @paramFileType In ('MSGFDB', 'DIA-NN', 'TopPIC')
                            Begin
                                -----------------------------------------
                                -- Determine the modification name (preferably UniMod name, but could also be a mass correction tag name)
                                -----------------------------------------                        
                                
                                If @paramFileType In ('MSGFDB', 'TopPIC')
                                Begin                                
                                    SELECT @modName = LTrim(RTrim(Value))
                                    FROM #Tmp_ModDef
                                    WHERE @paramFileType = 'MSGFDB'  And EntryID = 5 Or
                                          @paramFileType = 'TopPIC' And EntryID = 1
                            
                                    -- Auto change Glu->pyro-Glu to Dehydrated
                                    -- Both have empirical formula H(-2) O(-1) but DMS can only associate one UniMod name with each unique empirical formula and Dehydrated is associated with H(-2) O(-1)                        
                                    If @modName = 'Glu->pyro-Glu'
                                        Set @modName = 'Dehydrated'                                
                                End
                                Else
                                Begin
                                    -- DIA-NN parameter file
                                    --
                                    SELECT @field = LTrim(RTrim(Value))
                                    FROM #Tmp_ModDef
                                    WHERE EntryID = 1

                                    Set @lookupUniModID = 1
                                    Set @staticCysCarbamidomethyl = 0

                                    If Not @field Like 'UniMod:[0-9]%'
                                    Begin
                                        If @field = 'StaticCysCarbamidomethyl'
                                        Begin
                                            Set @field = 'UniMod:4'
                                            Set @staticCysCarbamidomethyl = 1
                                        End
                                        Else
                                        Begin
                                            If @validateUnimod > 0
                                            Begin
                                                Set @message = 'Mod name "' + @field + '" is not in the expected form (e.g. UniMod:35); see row: ' + @row
                                                Set @myError = 53016
                                                Goto Done
                                            End
                                            Else
                                            Begin
                                                Set @lookupUniModID = 0
                                            End
                                        End
                                    End

                                    If @lookupUniModID = 0
                                    Begin
                                        Set @modName = @field
                                    End
                                    Else
                                    Begin
                                        Set @uniModIDText = Substring(@field, 8, 100)
                                        Set @uniModID = Try_Parse(@uniModIDText As int)

                                        If @uniModID Is Null
                                        Begin
                                            Set @message = 'UniMod ID "' + @uniModIDText + '" is not an integer; see row: ' + @row
                                            Set @myError = 53017
                                            Goto Done
                                        End
                                    
                                        If @uniModID = 4 And @staticCysCarbamidomethyl = 0
                                        Begin
                                            Set @message = 'Define static Cys Carbamidomethyl using "StaticCysCarbamidomethyl=True", not using "StaticMod=UniMod:4"; see row: ' + @row
                                            Set @myError = 53018
                                            Goto Done
                                        End

                                        SELECT @modName = Name
                                        FROM Ontology_Lookup.dbo.T_Unimod_Mods
                                        WHERE Unimod_ID = @uniModID
                                        --
                                        SELECT @myRowCount = @@rowcount, @myError = @@error

                                        If @myRowCount = 0
                                        Begin
                                            Set @message = 'UniMod ID "' + @field + '" not found in T_Unimod_Mods; see row: ' + @row
                                            Set @myError = 53019
                                            Goto Done
                                        End
                                    End
                                End

                                -----------------------------------------
                                -- Determine the Mass_Correction_ID based on the UniMod name
                                -----------------------------------------                        
                                --
                                SELECT @massCorrectionID = Mass_Correction_ID, 
                                       @modMass = Monoisotopic_Mass
                                FROM T_Mass_Correction_Factors
                                WHERE Original_Source_Name = @modName AND
                                      (Original_Source = 'UniMod' OR @modName IN ('Heme_615','Dyn2DZ','DeoxyHex', 'Pentose') Or @validateUnimod = 0)
                                --
                                SELECT @myRowCount = @@rowcount, @myError = @@error

                                If (@myRowCount = 0 Or @massCorrectionID = 0) And @validateUnimod = 0
                                Begin
                                    -- No match, try matching the DMS name (Mass_Correction_Tag)
                                    --
                                    SELECT @massCorrectionID = Mass_Correction_ID
                                    FROM T_Mass_Correction_Factors
                                    WHERE Mass_Correction_Tag = @modName
                                    --
                                    SELECT @myRowCount = @@rowcount, @myError = @@error
                                End
                            
                                If @myRowCount = 0 Or IsNull(@massCorrectionID, 0) = 0
                                Begin
                                    If @validateUnimod > 0
                                        Set @message = 'UniMod modification not found in T_Mass_Correction_Factors.Original_Source_Name for mod "' + @modName + '"; see row: ' + @row
                                    else
                                        Set @message = 'Modification name not found in T_Mass_Correction_Factors.Original_Source_Name or T_Mass_Correction_Factors.Mass_Correction_Tag for mod "' + @modName + '"; see row: ' + @row
                                    
                                    Set @myError = 53007
                                    Goto Done
                                End
                            
                                -----------------------------------------
                                -- Determine the affected residues
                                -----------------------------------------
                                --
                                SELECT @location = LTrim(RTrim(Value))
                                FROM #Tmp_ModDef
                                WHERE @paramFileType = 'MSGFDB' And EntryID = 4 Or
                                      @paramFileType = 'TopPIC' And EntryID = 4
                            
                                If @paramFileType = 'MSGFDB' And @location Not In ('any', 'N-term', 'C-term', 'Prot-N-term', 'Prot-C-term')
                                Begin
                                    Set @message = 'Invalid location "' + @location + '"; should be "any", "N-term", "C-term", "Prot-N-term", or "Prot-C-term"; see row: ' + @row
                                    Set @myError = 53008
                                    Goto Done
                                End

                                If @paramFileType = 'TopPIC' And @location Not In ('any', 'N-term', 'C-term')
                                Begin
                                    Set @message = 'Invalid location "' + @location + '"; should be "any", "N-term", or "C-term"; see row: ' + @row
                                    Set @myError = 53008
                                    Goto Done
                                End
                            
                                If @paramFileType = 'DIA-NN'
                                Begin
                                    SELECT @field = LTrim(RTrim(Value))
                                    FROM #Tmp_ModDef
                                    WHERE @paramFileType = 'DIA-NN' And EntryID = 3
                                          
                                    If @field = '*n'
                                        Set @location = 'Prot-N-term'   -- Protein N-terminus
                                    Else If ascii(@field) = 110
                                        Set @location = 'N-term'        -- Peptide N-terminus (lowercase 'n' is ASCII 110)
                                    Else
                                        Set @location = 'any'
                                End

                                If @location = 'Prot-N-term'
                                Begin
                                    Set @terminalMod = 1
                                    INSERT INTO #Tmp_Residues (Residue_Symbol, Terminal_AnyAA) Values ('[', 1)
                                End
                                                            
                                If @location = 'Prot-C-term'
                                Begin
                                    Set @terminalMod = 1
                                    INSERT INTO #Tmp_Residues (Residue_Symbol, Terminal_AnyAA) Values (']', 1)
                                End
                            
                                If @location = 'N-term'
                                Begin
                                    Set @terminalMod = 1
                                    INSERT INTO #Tmp_Residues (Residue_Symbol, Terminal_AnyAA) Values ('<', 1)
                                End
                                
                                If @location = 'C-term'
                                Begin
                                    Set @terminalMod = 1
                                    INSERT INTO #Tmp_Residues (Residue_Symbol, Terminal_AnyAA) Values ('>', 1)
                                End
                            
                                -- Parse out the affected residue (or residues)
                                -- In MS-GF+ and TOPPIC, N- or C-terminal mods use * for any residue at a terminus
                                --                        
                                SELECT @field = LTrim(RTrim(Value))
                                FROM #Tmp_ModDef
                                WHERE EntryID = 2 And @paramFileType In ('MSGFDB') Or
                                      EntryID = 3 And @paramFileType In ('DIA-NN', 'TopPIC')
                            
                                If @field = 'any'
                                Begin
                                    Set @message = 'Use * to match all residues, not the word "any"; see row: ' + @row
                                    Set @myError = 53010
                                    Goto Done
                                End

                                Set @affectedResidues = @field
                            End -- MS-GF+ , DIA-NN, and TopPIC

                            If @paramFileType In ('MSFragger')
                            Begin
                                -----------------------------------------
                                -- Determine the Mass_Correction_ID based on the mod mass
                                -----------------------------------------                        
                                --
                                SELECT @field = LTrim(RTrim(Value))
                                FROM #Tmp_ModDef
                                WHERE EntryID = 1

                                Set @modMassToFind = Try_Parse(@field As float)

                                If @modMassToFind Is Null
                                Begin
                                    Set @message = 'Mod mass "' + @field + '" is not a number; see row: ' + @row
                                    Set @myError = 53012
                                    Goto Done
                                End

                                If Abs(@modMassToFind) < 0.01
                                Begin
                                    -- Likely an undefined static mod, e.g. add_T_threonine = 0.0000
                                    -- Skip it
                                    Set @validRow = 0
                                End
                                Else
                                Begin
                                    SELECT Top 1 @massCorrectionID = Mass_Correction_ID, @modName = Mass_Correction_Tag, @modMass = Monoisotopic_Mass
                                    FROM T_Mass_Correction_Factors
                                    WHERE Abs(Monoisotopic_Mass - @modMassToFind) < 0.25
                                    Order By Abs(Monoisotopic_Mass - @modMassToFind)
                                    --
                                    SELECT @myRowCount = @@rowcount, @myError = @@error

                                    If @myRowCount < 1 Or IsNull(@massCorrectionID, 0) = 0
                                    Begin
                                        Set @message = 'Matching modification not found for mass ' + Cast(@modMassToFind As Varchar(20)) + 
                                                       ' in T_Mass_Correction_Factors; see row: ' + @row
                                        Set @myError = 53007
                                        Goto Done
                                    End

                                    SELECT @affectedResidues = LTrim(RTrim(Value))
                                    FROM #Tmp_ModDef
                                    WHERE EntryID = 2

                                    If @affectedResidues In ('<','>','[',']')
                                    Begin
                                        -- N or C terminal static mod 
                                        -- (specified with add_Cterm_peptide or similar, 
                                        --  but we replaced that with a symbol earlier in this procedure)
                                        Set @terminalMod = 1

                                        INSERT INTO #Tmp_Residues (Residue_Symbol, Terminal_AnyAA) Values (@affectedResidues, 1)
                                        Set @affectedResidues= '*'
                                    End
                                    Else If @affectedResidues In ('[^', ']^', 'n^')
                                    Begin
                                        -- N or C terminal dynamic mod 
                                        Set @terminalMod = 1

                                        -- Override 'n^' to instead use '[^'
                                        If @affectedResidues = 'n^'
                                            Set @affectedResidues = '[^'

                                        INSERT INTO #Tmp_Residues (Residue_Symbol, Terminal_AnyAA) Values (Substring(@affectedResidues, 1, 1), 1)
                                        Set @affectedResidues= '*'
                                    End
                                End
                            End -- MSFragger

                            If @paramFileType In ('MaxQuant')
                            Begin
                                -----------------------------------------
                                -- Determine the Mass_Correction_ID and affected residues based on the mod name
                                -----------------------------------------                        
                                --
                                SELECT @field = LTrim(RTrim(Value))
                                FROM #Tmp_ModDef
                                WHERE EntryID = 1

                                SELECT @maxQuantModID = Mod_ID,
                                       @location = Mod_Position,
                                       @massCorrectionID = Mass_Correction_ID,
                                       @isobaricModIonNumber = Isobaric_Mod_Ion_Number
                                FROM T_MaxQuant_Mods
                                WHERE Mod_Title = @field
                                --
                                SELECT @myRowCount = @@rowcount, @myError = @@error

                                If @myRowCount = 0
                                Begin
                                    Set @message = 'MaxQuant modification not found in T_MaxQuant_Mods: ' + @field
                                    Set @myError = 53015
                                    Goto Done
                                End

                                If IsNull(@massCorrectionID, 0) = 0
                                Begin                                
                                    Set @message = 'Mass Correction ID not defined for MaxQuant modification "' + @field + '"; either update table T_MaxQuant_Mods or delete this mod from the XML'
                                    Set @myError = 53015
                                    Goto Done
                                End

                                SELECT TOP 1 @massCorrectionID = Mass_Correction_ID,
                                             @modName = Mass_Correction_Tag,
                                             @modMass = Monoisotopic_Mass
                                FROM T_Mass_Correction_Factors
                                WHERE Mass_Correction_ID = @massCorrectionID
                                --
                                SELECT @myRowCount = @@rowcount, @myError = @@error                                                                       

                                -- Lookup the affected residues
                                Set @affectedResidues= ''

                                SELECT @affectedResidues = @affectedResidues + R.Residue_Symbol
                                FROM T_MaxQuant_Mod_Residues M
                                     INNER JOIN T_Residues R
                                       ON M.Residue_ID = R.Residue_ID
                                WHERE Mod_ID = @maxQuantModID
                                --
                                SELECT @myRowCount = @@rowcount, @myError = @@error
                                
                                If @location = 'proteinNterm'
                                Begin
                                    Set @terminalMod = 1
                                    Set @affectedResidues = '*'
                                    INSERT INTO #Tmp_Residues (Residue_Symbol, Terminal_AnyAA) Values ('[', 1)
                                End
                                                            
                                If @location = 'proteinCterm'
                                Begin
                                    Set @terminalMod = 1
                                    Set @affectedResidues = '*'
                                    INSERT INTO #Tmp_Residues (Residue_Symbol, Terminal_AnyAA) Values (']', 1)
                                End
                            
                                If @location in ('anyNterm', 'notNterm')
                                Begin
                                    Set @terminalMod = 1
                                    If IsNull(@affectedResidues, '') = '' Or Not @affectedResidues LIKE '[A-Z]'
                                        Set @affectedResidues = '<'

                                    INSERT INTO #Tmp_Residues (Residue_Symbol, Terminal_AnyAA) Values (@affectedResidues, 1)
                                End
                                
                                If @location in ('anyCterm', 'notCterm')
                                Begin
                                    Set @terminalMod = 1
                                    If IsNull(@affectedResidues, '') = '' Or Not @affectedResidues LIKE '[A-Z]'
                                        Set @affectedResidues = '>'

                                    INSERT INTO #Tmp_Residues (Residue_Symbol, Terminal_AnyAA) Values (@affectedResidues, 1)
                                End                            
                            End -- MaxQuant

                            If @validRow > 0
                            Begin
                                -- Parse each character in @affectedResidues
                                Set @charIndex = 0
                                While @charIndex < Len(@affectedResidues)
                                Begin
                                    Set @charIndex = @charIndex + 1

                                    Set @residueSymbol = SubString(@affectedResidues, @charIndex, 1)
                                
                                    If @terminalMod = 1
                                    Begin
                                        If @paramFileType = 'DIA-NN'
                                        Begin
                                            -- This should be a peptide or protein N-terminal mod
                                            -- Break out of the while loop
                                            Set @charIndex = Len(@affectedResidues)
                                        End

                                        If Not @residueSymbol In ('*', '<', '>', '[', ']')
                                        Begin
                                            -- Terminal mod that targets specific residues
                                            -- Store this as a dynamic terminal mod
                                            UPDATE #Tmp_Residues 
                                            SET Terminal_AnyAA = 0
                                        
                                            -- Break out of the while loop
                                            Set @charIndex = Len(@affectedResidues)
                                        End
                                    End
                                    Else
                                    Begin
                                        -- Not matching an N or C-Terminus
                                        If @paramFileType In ('MSFragger')
                                        Begin
                                            If ASCII(@residueSymbol) In (110, 99)
                                            Begin
                                                -- Lowercase n or c indicates peptide N- or C-terminus
                                                If @charIndex = Len(@affectedResidues)
                                                Begin
                                                    Set @message = 'Lowercase n or c should be followed by a residue or *; see row: ' + @row
                                                    Set @myError = 53013
                                                    Goto Done
                                                End

                                                Set @charIndex = @charIndex + 1
                                                Set @residueSymbol = SubString(@affectedResidues, @charIndex, 1)
                                            End
                                        End

                                        INSERT INTO #Tmp_Residues (Residue_Symbol) 
                                        Values (@residueSymbol)
                                    End
                                
                                End

                                -----------------------------------------
                                -- Determine the residue IDs for the entries in #Tmp_Residues
                                -----------------------------------------
                                --
                                UPDATE #Tmp_Residues
                                SET Residue_ID = R.Residue_ID,
                                    Residue_Desc = R.Description
                                FROM #Tmp_Residues
                                     INNER JOIN T_Residues R
                                       ON R.Residue_Symbol = #Tmp_Residues.Residue_Symbol

                                If @infoOnly > 1
                                Begin
                                    Select * From #Tmp_Residues
                                End

                                -- Look for symbols that did not resolve
                                IF EXISTS (SELECT * FROM #Tmp_Residues WHERE Residue_ID IS Null)
                                Begin
                                    Set @msgAddon = ''
                                
                                    SELECT @msgAddon = @msgAddon + Case When @msgAddon = '' Then '' Else ', ' End + Residue_Symbol
                                    FROM #Tmp_Residues
                                    WHERE Residue_ID Is Null
                                
                                    Set @message = 'Unrecognized residue symbol(s) "' + @msgAddon + '"; symbols not found in T_Residues; see row: ' + @row
                                    Set @myError = 53009
                                    Goto Done
                                End
                            
                                -----------------------------------------
                                -- Check for N-terminal or C-terminal static mods that do not use *
                                -----------------------------------------
                                --
                                If @modTypeSymbol = 'S' And Exists (Select * From #Tmp_Residues Where Residue_Symbol In ('<', '>') AND Terminal_AnyAA = 0)
                                Begin
                                    -- Auto-switch to tracking as a dynamic mod (required for PHRP)
                                    Set @modTypeSymbol = 'D'
                                End
                            
                                -----------------------------------------
                                -- Determine the Local_Symbol_ID to store for dynamic mods
                                -----------------------------------------
                                --
                                If @modTypeSymbol = 'D'
                                Begin
                                    If Exists (SELECT * FROM #Tmp_ModsToStore WHERE Mod_Name = @modName AND Mod_Type_Symbol = 'D')
                                    Begin
                                        -- This DynamicMod entry uses the same mod name as a previous one; re-use it
                                        SELECT TOP 1 @localSymbolIDToStore = Local_Symbol_ID
                                        FROM #Tmp_ModsToStore
                                        WHERE Mod_Name = @modName AND Mod_Type_Symbol = 'D'
                                    End
                                    Else
                                    Begin
                                        -- New dynamic mod
                                        Set @localSymbolID = @localSymbolID + 1
                                        Set @localSymbolIDToStore = @localSymbolID
                                    End                                
                                
                                End
                                Else
                                Begin
                                    -- Static mod; store 0
                                    Set @localSymbolIDToStore = 0
                                End
                            
                                If @isobaricModIonNumber > 0
                                Begin
                                    -----------------------------------------
                                    -- Check whether this isobaric mod already exists in #Tmp_ModsToStore
                                    -----------------------------------------
                                    -- 
                                    SELECT @modTypeSymbolToStore = CASE
                                                                       WHEN @modTypeSymbol = 'S' AND
                                                                            Residue_Symbol IN ('<', '>') THEN 'T'
                                                                       ELSE @modTypeSymbol
                                                                   END,
                                           @residueSymbol = Residue_Symbol
                                    FROM #Tmp_Residues
                                    
                                    If Exists(
                                            SELECT *
                                            FROM #Tmp_ModsToStore
                                            WHERE Mod_Name = @modName AND
                                                  Mass_Correction_ID = @massCorrectionID AND
                                                  Mod_Type_Symbol = @modTypeSymbolToStore AND
                                                  Residue_Symbol = @residueSymbol AND
                                                  Abs(Monoisotopic_Mass - @modMass) < 0.0001 )
                                    Begin
                                        -- Mod already stored; skip it
                                        Set @validRow = 0

                                        Print 'Skipping row since the isobaric mod has already been stored: ' + @row
                                    End
                                End

                                If @validRow > 0
                                Begin
                                    -----------------------------------------
                                    -- Append the mod defs to #Tmp_ModsToStore
                                    -----------------------------------------
                                    --
                                    INSERT INTO #Tmp_ModsToStore (
                                            Mod_Name,
                                            Mass_Correction_ID,
                                            Mod_Type_Symbol,
                                            Residue_Symbol,
                                            Residue_ID,
                                            Local_Symbol_ID,
                                            Residue_Desc,
                                            Monoisotopic_Mass,
                                            MaxQuant_Mod_ID,
                                            Isobaric_Mod_Ion_Number
                                        )
                                    SELECT @modName AS Mod_Name,
                                           @massCorrectionID AS MassCorrectionID,
                                           CASE WHEN @modTypeSymbol = 'S' And Residue_Symbol IN ('<', '>') Then 'T' Else @modTypeSymbol End AS Mod_Type,
                                           Residue_Symbol,
                                           Residue_ID,
                                           @localSymbolIDToStore as Local_Symbol_ID,
                                           Residue_Desc,
                                           @modMass,
                                           @maxQuantModID,
                                           IsNull(@isobaricModIonNumber, 0)
                                    FROM #Tmp_Residues
                                End
                            End
                        End
                    End
                End
            End
        End
    End
        
    If @infoOnly <> 0
    Begin
        -- Preview the mod defs
        SELECT #Tmp_ModsToStore.*,
               @paramFileID AS Param_File_ID,
               @paramFileName AS Param_File,
               CASE
                   WHEN LookupQ.Min_Isobaric_Mod_Ion_Number IS NULL THEN 
                     'Duplicate isobaric mod that will be skipped'
                   ELSE ''
               END AS Isobaric_Mod_Comment
        FROM #Tmp_ModsToStore
             LEFT OUTER JOIN ( SELECT Residue_ID,
                                      Local_Symbol_ID,
                                      Mass_Correction_ID,
                                      Mod_Type_Symbol,
                                      Min(Isobaric_Mod_Ion_Number) AS Min_Isobaric_Mod_Ion_Number
                               FROM #Tmp_ModsToStore
                               GROUP BY Residue_ID, Local_Symbol_ID, Mass_Correction_ID, Mod_Type_Symbol) AS LookupQ
               ON #Tmp_ModsToStore.Residue_ID = LookupQ.Residue_ID AND
                  #Tmp_ModsToStore.Local_Symbol_ID = LookupQ.Local_Symbol_ID AND
                  #Tmp_ModsToStore.Mass_Correction_ID = LookupQ.Mass_Correction_ID AND
                  #Tmp_ModsToStore.Mod_Type_Symbol = LookupQ.Mod_Type_Symbol AND
                  #Tmp_ModsToStore.Isobaric_Mod_Ion_Number = LookupQ.Min_Isobaric_Mod_Ion_Number
    End
    
    If @infoOnly = 0 And @validateOnly = 0
    Begin
        -- Store the mod defs
        
        Declare @storeMods varchar(24) = 'StoreMods'
        
        Begin Tran @storeMods
        
        If Exists (SELECT * FROM T_Param_File_Mass_Mods WHERE Param_File_ID = @paramFileID)
        Begin
            DELETE T_Param_File_Mass_Mods WHERE Param_File_ID = @paramFileID
        End
        
        INSERT INTO T_Param_File_Mass_Mods (Residue_ID, Local_Symbol_ID, Mass_Correction_ID, Param_File_ID, Mod_Type_Symbol, MaxQuant_Mod_ID)
        SELECT Residue_ID, Local_Symbol_ID, Mass_Correction_ID, @paramFileID, Mod_Type_Symbol, MaxQuant_Mod_ID
        FROM #Tmp_ModsToStore        
    
        Commit Tran @storeMods
        
        SELECT *
        FROM V_Param_File_Mass_Mods
        WHERE Param_File_ID = @paramFileID

    End
    
Done:

    If @infoOnly <> 0 
    Begin
        If Len(@message) > 0
            SELECT @message As Message

        If @myError > 0
            SELECT * From #Tmp_ModDef
    End

    If @infoOnly = 0 And @myError > 0
        Print @message


    If @tempTablesCreated > 0
    Begin
        DROP TABLE #Tmp_Mods
        DROP TABLE #Tmp_ModDef    
        DROP TABLE #Tmp_Residues    
        DROP TABLE #Tmp_ModsToStore
    End
        
    --
    Return @myError


GO
GRANT VIEW DEFINITION ON [dbo].[StoreParamFileMassMods] TO [DDL_Viewer] AS [dbo]
GO
