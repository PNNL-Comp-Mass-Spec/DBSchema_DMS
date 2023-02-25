/****** Object:  StoredProcedure [dbo].[add_update_settings_file] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[add_update_settings_file]
/****************************************************
**
**  Desc: Adds new or edits existing entity in T_Settings_Files table
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**  Date:   08/22/2008
**          03/30/2015 mem - Added parameters @hmsAutoSupersede and @msgfPlusAutoCentroid
**          03/21/2016 mem - Update column Last_Updated
**          06/13/2017 mem - Use SCOPE_IDENTITY()
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          12/10/2018 mem - Rename parameters and make @settingsFileID an output parameter
**          04/11/2022 mem - Check for existing settings file (by name) when @mode is 'add'
**                         - Check for whitespace in @fileName
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
** Pacific Northwest National Laboratory, Richland, WA
** Copyright 2008, Battelle Memorial Institute
*****************************************************/
(
    @settingsFileID int output,                 -- Settings file ID to edit, or the ID of the newly created settings file
    @analysisTool varchar(64),
    @fileName varchar(255),
    @description varchar(1024),
    @active tinyint,
    @contents text,
    @hmsAutoSupersede varchar(255) = '',        -- Settings file name to use instead of this settings file if the dataset comes from a high res MS instrument
    @msgfPlusAutoCentroid varchar(255) = '',    -- Settings file name to use instead of this settings file if MSGF+ reports that not enough spectra are centroided; see SP auto_reset_failed_jobs
    @mode varchar(12) = 'add',                  -- 'add' or 'update'
    @message varchar(512) output,
    @callingUser varchar(128) = ''
)
AS
    Set XACT_ABORT, nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Set @message = ''

    Declare @xmlContents xml
    Set @xmlContents = @contents

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = verify_sp_authorized 'add_update_settings_file', @raiseError = 1
    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;

    ---------------------------------------------------
    -- Validate the inputs
    ---------------------------------------------------

    Set @analysisTool = LTrim(RTrim(IsNull(@analysisTool, '')))
    Set @fileName = LTrim(RTrim(IsNull(@fileName, '')))
    Set @hmsAutoSupersede = LTrim(RTrim(IsNull(@hmsAutoSupersede, '')))
    Set @msgfPlusAutoCentroid = LTrim(RTrim(IsNull(@msgfPlusAutoCentroid, '')))

    If @analysisTool = ''
    Begin
        Set @message = 'Analysis Tool cannot be empty'
        RAISERROR (@message, 10, 1)
        return 51006
    End

    If @fileName = ''
    Begin
        Set @message = 'Filename cannot be empty'
        RAISERROR (@message, 10, 1)
        return 51006
    End

    If dbo.has_whitespace_chars(@fileName, 0) > 0
    Begin
        If CharIndex(Char(9), @fileName) > 0
            RAISERROR ('Settings file name cannot contain tabs', 11, 116)
        Else
            RAISERROR ('Settings file name cannot contain spaces', 11, 116)
    End

    If Len(@hmsAutoSupersede) > 0
    Begin
        If @hmsAutoSupersede = @fileName
        Begin
            Set @message = 'The HMS_AutoSupersede file cannot have the same name as this settings file'
            RAISERROR (@message, 10, 1)
            return 51006
        End

        If Not Exists (SELECT * FROM T_Settings_Files WHERE File_name = @hmsAutoSupersede)
        Begin
            Set @message = 'HMS_AutoSupersede settings file not found in the database: ' + @hmsAutoSupersede
            RAISERROR (@message, 10, 1)
            return 51006
        End

        Declare @AnalysisToolForAutoSupersede varchar(64) = ''

        SELECT @AnalysisToolForAutoSupersede = Analysis_Tool
        FROM T_Settings_Files
        WHERE File_name = @hmsAutoSupersede

        If @AnalysisToolForAutoSupersede <> @analysisTool
        Begin
            Set @message = 'The Analysis Tool for the HMS_AutoSupersede file ("' + @hmsAutoSupersede + '") must match the analysis tool for this settings file: ' + @AnalysisToolForAutoSupersede + ' vs. ' + @analysisTool
            RAISERROR (@message, 10, 1)
            return 51006
        End

    End
    Else
    Begin
        Set @hmsAutoSupersede = null
    End

    If Len(@msgfPlusAutoCentroid) > 0
    Begin
        If @msgfPlusAutoCentroid = @fileName
        Begin
            Set @message = 'The MSGFPlus_AutoCentroid file cannot have the same name as this settings file'
            RAISERROR (@message, 10, 1)
            return 51006
        End

        If Not Exists (SELECT * FROM T_Settings_Files WHERE File_name = @msgfPlusAutoCentroid)
        Begin
            Set @message = 'MSGFPlus AutoCentroid settings file not found in the database: ' + @msgfPlusAutoCentroid
            RAISERROR (@message, 10, 1)
            return 51006
        End

        Declare @AnalysisToolForAutoCentroid varchar(64) = ''

        SELECT @AnalysisToolForAutoCentroid = Analysis_Tool
        FROM T_Settings_Files
        WHERE File_name = @msgfPlusAutoCentroid

        If @AnalysisToolForAutoCentroid <> @analysisTool
        Begin
            Set @message = 'The Analysis Tool for the MSGFPlus_AutoCentroid file ("' + @msgfPlusAutoCentroid + '") must match the analysis tool for this settings file: ' + @AnalysisToolForAutoCentroid + ' vs. ' + @analysisTool
            RAISERROR (@message, 10, 1)
            return 51006
        End

    End
    Else
    Begin
        Set @msgfPlusAutoCentroid = null
    End

    If @mode = 'add'
    Begin
        ---------------------------------------------------
        -- Check for an existing settings file
        ---------------------------------------------------

        SELECT @settingsFileID = ID
        FROM T_Settings_Files
        WHERE File_Name = @fileName
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @myRowCount > 0
        Begin
            Set @message = 'Settings file ID ' + Cast(@settingsFileID As varchar(12))+ ' is named "' + @fileName + '"; cannot create a new, duplicate settings file'
            RAISERROR (@message, 10, 1)
            return 51007
        End
    End

    If @mode = 'update'
    Begin
        ---------------------------------------------------
        -- Assure that the settings file exists
        ---------------------------------------------------

        If @settingsFileID Is Null
        Begin
            Set @message = 'Settings file ID is null; cannot udpate'
            RAISERROR (@message, 10, 1)
            return 51007
        End

        -- Cannot update a non-existent entry
        --
        --
        If Not Exists (SELECT * FROM T_Settings_Files WHERE ID = @settingsFileID)
        Begin
            Set @message = 'Settings file ID ' + Cast(@settingsFileID As varchar(12))+ ' not found in database; cannot update'
            RAISERROR (@message, 10, 1)
            return 51007
        End

    End


    ---------------------------------------------------
    -- action for add mode
    ---------------------------------------------------
    --
    If @mode = 'add'
    Begin

        INSERT INTO T_Settings_Files(
            Analysis_Tool,
            File_Name,
            Description,
            Active,
            Contents,
            HMS_AutoSupersede,
            MSGFPlus_AutoCentroid
        ) VALUES (
            @analysisTool,
            @fileName,
            @description,
            @active,
            @xmlContents,
            @hmsAutoSupersede,
            @msgfPlusAutoCentroid
        )
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
        Begin
            Set @message = 'Insert operation failed'
            RAISERROR (@message, 10, 1)
            return 51007
        End

        -- Return ID of newly created entry
        --
        Set @settingsFileID = SCOPE_IDENTITY()

    End -- add mode

    ---------------------------------------------------
    -- action for update mode
    ---------------------------------------------------
    --
    If @mode = 'update'
    Begin
        Set @myError = 0

        UPDATE T_Settings_Files
        SET Analysis_Tool = @analysisTool,
            File_Name = @fileName,
            Description = @description,
            Active = @active,
            Contents = @xmlContents,
            HMS_AutoSupersede = @hmsAutoSupersede,
            MSGFPlus_AutoCentroid = @msgfPlusAutoCentroid,
            Last_Updated = GetDate()
        WHERE ID = @settingsFileID
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
        Begin
            Set @message = 'Update operation failed: ID "' + @settingsFileID + '"'
            RAISERROR (@message, 10, 1)
            return 51004
        End
    End -- update mode

    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[add_update_settings_file] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[add_update_settings_file] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[add_update_settings_file] TO [Limited_Table_Write] AS [dbo]
GO
