/****** Object:  StoredProcedure [dbo].[StoreParamFileMassMods] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure [dbo].[StoreParamFileMassMods]
/****************************************************
**
**  Stores (or validates) the dynamic and static mods to associate with a given parameter file
**
**  Mods must be defined in the format used for MSGF+ parameter files or for TopPIC parameter files
**
**  MSGF+ parameter file format:
**     The mod names listed in the 5th comma-separated column must be Unimod names 
**     and must match the Original_Source_Name values in T_Mass_Correction_Factors
**
**     StaticMod=144.102063,  *,  fix, N-term,    iTRAQ4plex           # 4-plex iTraq
**     StaticMod=144.102063,  K,  fix, any,       iTRAQ4plex           # 4-plex iTraq
**     StaticMod=C2H3N1O1,    C,  fix, any,       Carbamidomethyl      # Fixed Carbamidomethyl C (alkylation)
**
**     DynamicMod=HO3P, STY, opt, any,            Phospho              # Phosphorylation STY
**
**  TopPIC parameter file format:
**     The format is Unimod Name, Mass, Residues, Position, UnimodID
**     The UnimodName in the first column should match the Original_Source_Name values in T_Mass_Correction_Factors
**
**     StaticMod=Carbamidomethylation,57.021464,C,any,4
**     StaticMod=TMT6plex,229.1629,*,N-term,737
**     StaticMod=TMT6plex,229.1629,K,any,737
**
**     DynamicMod=Phospho,79.966331,STY,any,21
**     DynamicMod=Oxidation,15.994915,CPKDNRY,any,35
**     DynamicMod=Methyl,14.015650,*,N-term,34
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
**    
*****************************************************/
(
    @paramFileID int,            -- If 0 or a negative number, will validate the mods without updating any tables
    @mods varchar(max),
    @infoOnly tinyint = 0,
    @replaceExisting tinyint = 0,
    @validateUnimod tinyint = 1,
    @paramFileType varchar(50) = '',    -- MSGFDB or TopPIC; if empty, will lookup using @paramFileID; if no match (or if @paramFileID is null or 0) assumes MSGFDB (aka MSGF+)
    @message varchar(512)='' OUTPUT
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
    
    If Not @paramFileType In ('MSGFDB', 'TopPIC')
    Begin
        Set @paramFileType = 'MSGFDB'
    End

    -----------------------------------------
    -- Create some temporary tables
    -----------------------------------------
    
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
        Residue_Desc varchar(64) NULL
    )
    
    CREATE UNIQUE CLUSTERED INDEX #IX_Tmp_ModsToStore ON #Tmp_ModsToStore (Entry_ID)
    
    Set @tempTablesCreated = 1
    
    -----------------------------------------
    -- Split @mods on carriage returns
    -- Store the data in #Tmp_Mods
    -----------------------------------------

    Declare @delimiter varchar(1) = ''

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
    

    Declare @continue tinyint = 1
    Declare @entryID int = 0
    Declare @entryIDEnd int = 0
    
    Declare @charIndex int
    Declare @colCount int
    
    Declare @row varchar(2048)
    Declare @field varchar(512)
    Declare @modType varchar(128)
    Declare @modTypeSymbol varchar(1)
    Declare @massCorrectionID int
    
    Declare @modName varchar(255)
    Declare @location varchar(128)
    
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
    While @entryID < @entryIDEnd
    Begin
        SELECT TOP 1 @entryID = EntryID, @row = Value
        FROM #Tmp_Mods
        WHERE EntryID > @entryID
        ORDER BY EntryID
        --
        SELECT @myRowCount = @@rowcount, @myError = @@error
        
        -- @row show now be empty, or contain something like the following:
        -- StaticMod=144.102063,  *,  fix, N-term,    iTRAQ4plex             # 4-plex iTraq
        --   or
        -- DynamicMod=HO3P, STY, opt, any,            Phospho            # Phosphorylation STY
        --   or 
        -- StaticMod=Carbamidomethylation,57.021464,C,any,4
        --   or 
        -- DynamicMod=Phospho,79.966331,STY,any,21
        
        Set @charIndex = CharIndex('#', @row)
        If @charIndex > 0
            Set @row= SubString(@row, 1, @charIndex-1)
        
        Set @row = Replace (@row, CHAR(10), '')
        Set @row = Replace (@row, CHAR(13), '')
        Set @row = Replace (@row, CHAR(9), ' ')
        Set @row = LTrim(RTrim(IsNull(@row, '')))
        
        If @row <> ''
        Begin
            If @infoOnly <> 0
                Print @row

            DELETE FROM #Tmp_ModDef
            
            INSERT INTO #Tmp_ModDef (EntryID, Value)
            SELECT EntryID, Value
            FROM dbo.udfParseDelimitedListOrdered(@row, ',', 0)
            
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
                Set @field = 1
                SELECT @field = LTrim(RTrim(Value))
                FROM #Tmp_ModDef
                WHERE EntryID = 1
                
                -- @field should now look something like the following:
                -- StaticMod=None
                -- DynamicMod=None
                -- DynamicMod=O1
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

                        -- Assure that #Tmp_ModDef has at least 5 columns
                        --
                        SELECT @colCount = COUNT(*) 
                        FROM #Tmp_ModDef
                
                        If @colCount < 5
                        Begin
                            If CharIndex(Char(9), @row) > 0
                            Begin
                                If CharIndex(',', @row) > 0
                                    Set @message = 'Row has a mix of tabs and commas; should only be comma-separated: ' + @row
                                Else
                                    Set @message = 'Row appears to be tab separated instead of comma-separated: ' + @row
                                    
                                Set @myError = 53011
                                If @infoOnly = 0
                                    Goto Done
                            End
                            Else
                            Begin
                                -- MSGF+ uses  'StaticMod=None' and 'DynamicMod=None' to indicate no static or dynamic mods
                                -- TopPIC uses 'StaticMod=None' and 'DynamicMod=Defaults' to indicate no static or dynamic mods
                                If Not @field in ('StaticMod=None', 'DynamicMod=None', 'DynamicMod=Defaults')
                                Begin
                                    Set @message = 'Skipping row since it has ' + Cast(@colCount as varchar(4)) + ' comma-separated columns (should have 5 columns): ' + @row
                                    Set @myError = 53012
                                    
                                    If @infoOnly = 0
                                        Goto Done
                                End
                            End
                            
                        End
                        Else
                        Begin

                            Set @field = ''
                            If @paramFileType = 'TopPIC'
                            Begin
                                -- TopPIC mod defs don't include 'opt' or 'fix, so we update @field based on @modType
                                If @modType = 'DynamicMod'
                                    Set @field = 'opt'
                                If @modType = 'StaticMod'
                                    Set @field = 'fix'
                            End
                            Else
                            Begin
                                -- MSGF+
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
                            
                            -----------------------------------------
                            -- Determine the Mass_Correction_ID based on the Unimod name
                            -----------------------------------------                        
                            --
                            Set @modName = ''

                            SELECT @modName = LTrim(RTrim(Value))
                            FROM #Tmp_ModDef
                            WHERE @paramFileType = 'MSGFDB' And EntryID = 5 Or
                                  @paramFileType = 'TopPIC' And EntryID = 1
                            
                            -- Auto change Glu->pyro-Glu to Dehydrated
                            -- Both have empirical formula H(-2) O(-1) but DMS can only associate one Unimod name with each unique empirical formula and Dehydrated is associated with H(-2) O(-1)                        
                            If @modName = 'Glu->pyro-Glu'
                                Set @modName = 'Dehydrated'
                                
                            Set @massCorrectionID = 0
                            --
                            SELECT @massCorrectionID = Mass_Correction_ID
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
                            
                            If @myRowCount = 0 Or @massCorrectionID = 0
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
                            Set @location = ''

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
                            
                            DELETE FROM #Tmp_Residues
                            Set @terminalMod = 0
                            
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
                            -- N- or C-terminal mods use * for any residue at a terminus
                            --                        
                            SELECT @field = LTrim(RTrim(Value))
                            FROM #Tmp_ModDef
                            WHERE @paramFileType = 'MSGFDB' And EntryID = 2 Or
                                  @paramFileType = 'TopPIC' And EntryID = 3
                            
                            If @field = 'any'
                            Begin
                                Set @message = 'Use * to match all residues, not the word "any"; see row: ' + @row
                                Set @myError = 53010
                                Goto Done
                            End
                            
                            -- Parse each character in @field
                            Set @charIndex = 0
                            While @charIndex < Len(@field)
                            Begin
                                Set @charIndex = @charIndex + 1

                                Set @residueSymbol = SubString(@field, @charIndex, 1)
                                
                                If @terminalMod = 1
                                Begin
                                    If @residueSymbol <> '*'
                                    Begin
                                        -- Terminal mod that targets specific residues
                                        -- Store this as a dynamic terminal mod
                                        UPDATE #Tmp_Residues 
                                        SET Terminal_AnyAA = 0
                                        
                                        Set @charIndex = Len(@field)
                                    End
                                End
                                Else
                                Begin
                                    -- Not matching an N or C-Terminus
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

                            -- Look for symbols that did not resolve
                            IF EXISTS (SELECT * FROM #Tmp_Residues WHERE Residue_ID IS NULL)
                            Begin
                                Set @msgAddon = Null
                                
                                SELECT @msgAddon = @msgAddon + Coalesce(@msgAddon + ', ', '') + Residue_Symbol
                                FROM #Tmp_Residues
                                WHERE Residue_ID Is Null
                                
                                Set @message = 'Unrecognized residue symbol(s)s "' + @msgAddon + '"; symbols not found in T_Residues; see row: ' + @row
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
                                    Residue_Desc
                                )
                            SELECT @modName AS Mod_Name,
                                   @massCorrectionID AS MassCorrectionID,
                                   CASE WHEN @modTypeSymbol = 'S' And Residue_Symbol IN ('<', '>') Then 'T' Else @modTypeSymbol End AS Mod_Type,
                                   Residue_Symbol,
                                   Residue_ID,
                                   @localSymbolIDToStore as Local_Symbol_ID,
                                   Residue_Desc
                            FROM #Tmp_Residues

                        End
                    End
                End
            End
        End
    End
    
    
    If @infoOnly <> 0
    Begin
        -- Preview the mod defs
        SELECT *, @paramFileID AS Param_File_ID, @paramFileName AS Param_File
        FROM #Tmp_ModsToStore
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
        
        INSERT INTO T_Param_File_Mass_Mods (Residue_ID, Local_Symbol_ID, Mass_Correction_ID, Param_File_ID, Mod_Type_Symbol)
        SELECT Residue_ID, Local_Symbol_ID, Mass_Correction_ID, @paramFileID, Mod_Type_Symbol
        FROM #Tmp_ModsToStore
    
        Commit Tran @storeMods
        
        SELECT *
        FROM V_Param_File_Mass_Mods
        WHERE Param_File_ID = @paramFileID

    End

    
Done:

    If @infoOnly <> 0 And Len(@message) > 0
        SELECT @message As Message

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
