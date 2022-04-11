/****** Object:  StoredProcedure [dbo].[AddUpdateParamFile] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[AddUpdateParamFile]
/****************************************************
**
**  Desc:
**      Adds new or updates existing parameter file in database
**
**      When updating an existing parameter file, the name and type can be changed
**      only if the file is not used with any analysis jobs
**
**  Auth:   kja
**  Date:   07/22/2004 kja - Initial version
**          12/06/2016 mem - Add parameters @paramFileID, @paramfileValid, @paramfileMassMods, and @replaceExistingMassMods
**                     mem - Replaced parameter @paramFileTypeID with @paramFileType
**          05/26/2017 mem - Update @paramfileMassMods to remove tabs
**          06/16/2017 mem - Restrict access using VerifySPAuthorized
**          08/01/2017 mem - Use THROW if not authorized
**          08/28/2017 mem - Add @validateUnimod
**          10/02/2017 mem - Abort adding a new parameter file if @paramfileMassMods does not validate (when @validateUnimod is 1)
**          08/17/2018 mem - Pass @paramFileType to StoreParamFileMassMods
**          11/19/2018 mem - Pass 0 to the @maxRows parameter to udfParseDelimitedListOrdered
**          11/30/2018 mem - Make @paramFileID an input/output parameter
**          11/04/2021 mem - Populate the Mod_List field using GetParamFileMassModCodeList
**          04/11/2022 mem - Check for whitespace in @paramFileName
**
*****************************************************/
(
    @paramFileID int output,
    @paramFileName varchar(255),
    @paramFileDesc varchar(1024),
    @paramFileType varchar(50),
    @paramfileValid tinyint = 1,                -- Forced to 1 if @mode is 'add'
    @paramfileMassMods varchar(4000) = '',
    @replaceExistingMassMods tinyint = 0,
    @validateUnimod tinyint = 1,
    @mode varchar(12) = 'add',                  -- 'add' or 'update'
    @message varchar(512) output
)
As
    Set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Set @message = ''

    Declare @msg varchar(256)
    Declare @updateMassMods tinyint = 0

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = VerifySPAuthorized 'AddUpdateParamFile', @raiseError = 1
    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;

    BEGIN TRY

    ---------------------------------------------------
    -- Validate input fields
    ---------------------------------------------------

    Set @mode = IsNull(@mode, 'add')

    If @paramFileID Is Null And Not @mode like '%add%'
    Begin
        Set @myError = 51010
        RAISERROR ('ParamFileID was null', 11, 1)
    End

    Set @paramFileName = LTrim(RTrim(IsNull(@paramFileName, '')))
    If @paramFileName = ''
    Begin
        Set @myError = 51000
        RAISERROR ('ParamFileName was blank', 11, 1)
    End

    Set @paramFileDesc = LTrim(RTrim(IsNull(@paramFileDesc, '')))
    If @paramFileDesc = ''
    Begin
        Set @myError = 51001
        RAISERROR ('ParamFileDesc was blank', 11, 1)
    End

    Set @paramFileType = LTrim(RTrim(IsNull(@paramFileType, '')))
    If @paramFileType = ''
    Begin
        Set @myError = 51002
        RAISERROR ('ParamFileType was null', 11, 1)
    End

    If dbo.udfWhitespaceChars(@paramFileName, 0) > 0
    Begin
        If CharIndex(Char(9), @paramFileName) > 0
            RAISERROR ('Parameter file name cannot contain tabs', 11, 116)
        Else
            RAISERROR ('Parameter file name cannot contain spaces', 11, 116)
    End

    Set @paramfileValid = IsNull(@paramfileValid, 1)

    Set @paramfileMassMods = IsNull(@paramfileMassMods, '')

    -- Assure that @paramfileMassMods does not have any tabs
    Set @paramfileMassMods = Replace(@paramfileMassMods, CHAR(9), ' ')

    Set @replaceExistingMassMods = IsNull(@replaceExistingMassMods, 0)

    Set @validateUnimod = IsNull(@validateUnimod, 1)

    If @myError <> 0
        return @myError

    ---------------------------------------------------
    -- Validate @paramFileType
    ---------------------------------------------------
    --

    Declare @paramFileTypeID int = 0

    SELECT @paramFileTypeID = Param_File_Type_ID
    FROM T_Param_File_Types
    WHERE Param_File_Type = @paramFileType

    If @paramFileTypeID = 0
    Begin
        Set @myError = 51003
        Set @msg = 'ParamFileType is not valid: ' + @paramFileType
        RAISERROR (@msg, 11, 1)
    End

    ---------------------------------------------------
    -- Is entry already in database?
    ---------------------------------------------------
    --
    Declare @existingParamFileID int = 0
    --
    execute @existingParamFileID = GetParamFileID @ParamFileName

    -- Check for a name conflict when adding
    --
    If @mode Like '%add%' And @existingParamFileID <> 0
    Begin
        Set @msg = 'Cannot add: Param File "' + @ParamFileName + '" already exists'
        RAISERROR (@msg, 11, 1)
    End

    -- Check for a name conflict when renaming
    --
    If @mode Like '%update%' And @existingParamFileID > 0 And @existingParamFileID <> @paramFileID
    Begin
        Set @msg = 'Cannot rename: Param File "' + @ParamFileName + '" already exists'
        RAISERROR (@msg, 11, 1)
    End

    ---------------------------------------------------
    -- Check for renaming or changing the type when the parameter file has already been used
    ---------------------------------------------------
    --
    If @mode Like '%update%'
    Begin
        Declare @currentName varchar(255) = ''
        Declare @currentTypeID int = 0

        SELECT @currentName = Param_File_Name,
               @currentTypeID = Param_File_Type_ID
        FROM T_Param_Files
        WHERE Param_File_ID = @paramFileID
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @paramFileName <> @currentName Or @paramFileTypeID <> @currentTypeID
        Begin
            Declare @action varchar(12) = 'rename'

            If @paramFileName = @currentName
            Begin
                Set @action = 'change param file type'
            End

            If Exists (SELECT * FROM T_Analysis_Job WHERE AJ_parmFileName = @currentName)
            Begin
                Set @msg = 'Cannot ' + @action + ': Param File "' + @currentName + '" is used by an analysis job'
                RAISERROR (@msg, 11, 1)
            End

            If Exists (SELECT * FROM T_Analysis_Job_Request WHERE AJR_parmFileName = @currentName)
            Begin
                Set @msg = 'Cannot ' + @action + ': Param File "' + @currentName + '" is used by a job request'
                RAISERROR (@msg, 11, 1)
            End
        End
    End

    If @paramfileMassMods <> ''
    Begin -- <a>
        -----------------------------------------
        -- Check whether all of the lines in @paramfileMassMods are blank or start with a # sign (comment character)
        -- Split @paramfileMassMods on carriage returns
        -- Store the data in #Tmp_Mods
        -----------------------------------------
        Declare @Delimiter varchar(1) = ''

        If CHARINDEX(CHAR(10), @paramfileMassMods) > 0
            Set @Delimiter = CHAR(10)
        Else
            Set @Delimiter = CHAR(13)

        CREATE TABLE #Tmp_Mods_Precheck (
            EntryID int NOT NULL,
            Value varchar(2048) null
        )

        INSERT INTO #Tmp_Mods_Precheck (EntryID, Value)
        SELECT EntryID, Value
        FROM dbo.udfParseDelimitedListOrdered(@paramfileMassMods, @Delimiter, 0)

        DELETE FROM #Tmp_Mods_Precheck
        WHERE Value Is Null Or Value Like '#%' or LTrim(RTrim(Value)) = ''

        If Not Exists (SELECT * FROM #Tmp_Mods_Precheck)
            Set @paramfileMassMods = ''

        If @paramfileMassMods <> '' And (
            @mode = 'add' OR
            @mode = 'update' And @replaceExistingMassMods = 1 OR
            @mode = 'update' And @replaceExistingMassMods = 0 AND Not Exists (Select * FROM T_Param_File_Mass_Mods WHERE Param_File_ID = @paramFileID))
        Begin -- <b>

            ---------------------------------------------------
            -- Validate the mods
            ---------------------------------------------------

            -- Store the param file mass mods in T_Param_File_Mass_Mods
            exec @myError = StoreParamFileMassMods
                 @paramFileID=0,
                 @mods=@paramfileMassMods,
                 @infoOnly=0,
                 @replaceExisting=1,
                 @validateUnimod=@validateUnimod,
                 @paramFileType=@paramFileType,
                 @message=@message output

            If @myError <> 0
            Begin
                If IsNull(@message, '') = ''
                    Set @msg = 'StoreParamFileMassMods returned error code ' + cast(@myError as varchar(9)) + '; unknown error'
                Else
                    Set @msg = 'StoreParamFileMassMods: "' + @message + '"'

                RAISERROR (@msg, 11, 1)
            End

        End -- </b>

    End -- </a>

    ---------------------------------------------------
    -- Action for add mode
    ---------------------------------------------------

    If @mode = 'add'
    Begin -- <add>

        INSERT INTO T_Param_Files (
            Param_File_Name,
            Param_File_Description,
            Param_File_Type_ID,
            Date_Created,
            Date_Modified,
            Valid
        ) VALUES (
            @ParamFileName,
            @ParamFileDesc,
            @ParamFileTypeID,
            GETDATE(),
            GETDATE(),
            1        -- Valid
        )
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
        Begin
            Set @msg = 'Insert operation failed: "' + @ParamFileName + '"'
            RAISERROR (@msg, 11, 1)
        End

        Set @paramFileID = SCOPE_IDENTITY()

        Set @updateMassMods = 1

    End -- </add>

    ---------------------------------------------------
    -- action for update mode
    ---------------------------------------------------
    --
    If @mode = 'update'
    Begin -- <update>

        UPDATE T_Param_Files
        SET Param_File_Name = @paramFileName,
            Param_File_Description = @ParamFileDesc,
            Param_File_Type_ID = @ParamFileTypeID,
            Valid = @paramfileValid,
            Date_Modified = GETDATE()
        WHERE Param_File_ID = @paramFileID
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
        Begin
            Set @msg = 'Update operation failed: "' + @ParamFileName + '"'
            RAISERROR (@msg, 11, 1)
        End

        Set @updateMassMods = 1

    End -- </update>

    If @paramFileID > 0 And @paramfileMassMods <> '' And @updateMassMods = 1
    Begin
        If @replaceExistingMassMods = 0 And Exists (Select * FROM T_Param_File_Mass_Mods WHERE Param_File_ID = @paramFileID)
        Begin
            Set @updateMassMods = 0
            Set @message = 'Warning: existing mass mods were not updated because @updateMassMods was 0'
        End

        If @updateMassMods = 1
        Begin
            -- Store the param file mass mods in T_Param_File_Mass_Mods
            exec @myError = StoreParamFileMassMods
                @paramFileID,
                @mods=@paramfileMassMods,
                @InfoOnly=0,
                @ReplaceExisting=@ReplaceExistingMassMods,
                @ValidateUnimod=@validateUnimod,
                @message=@message output

            If @myError <> 0
            Begin
                Set @msg = 'StoreParamFileMassMods: "' + @message + '"'
                RAISERROR (@msg, 11, 1)
            End
        End
    End

    If @mode In ('add', 'update')
    Begin
        -- Update the Mod_List field
        Update T_Param_Files
        Set Mod_List = dbo.GetParamFileMassModCodeList(Param_File_ID, 0)
        Where Param_File_ID = @paramFileID
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

    End

    END TRY
    BEGIN CATCH
        EXEC FormatErrorMessage @message output, @myError output

        -- rollback any open transactions
        IF (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;

        If Not @message Like '%already exists%' And
           Not @message Like '%was blank%' And
           Not @message Like '%is used by%' And
           Not @message Like '%%'
        Begin
            Declare @logMessage varchar(1024) = @message + '; Param file ' + @paramFileName
            exec PostLogEntry 'Error', @logMessage, 'AddUpdateParamFile'
        End

    END CATCH

Done:
    return @myError


GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateParamFile] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateParamFile] TO [DMS_Analysis] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateParamFile] TO [DMS_ParamFile_Admin] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateParamFile] TO [DMS_SP_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddUpdateParamFile] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AddUpdateParamFile] TO [Limited_Table_Write] AS [dbo]
GO
