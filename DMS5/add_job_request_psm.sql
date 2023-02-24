/****** Object:  StoredProcedure [dbo].[AddJobRequestPSM] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[AddJobRequestPSM]
/****************************************************
**
**  Desc:
**  Create a job from simplified interface
**
**  Return values: 0: success, otherwise, error code
**
**
**  Auth:   grk
**  Date:   11/14/2012 grk - Initial release
**          11/16/2012 grk - Added
**          11/20/2012 grk - Added @organismName
**          11/21/2012 mem - Now calling CreatePSMJobRequest
**          12/13/2012 mem - Added support for @mode='preview'
**          02/23/2016 mem - Add set XACT_ABORT on
**          04/12/2017 mem - Log exceptions to T_Log_Entries
**          05/23/2018 mem - Use a non-zero return code when @mode is 'preview'
**
*****************************************************/
(
    @requestID int output,
    @requestName varchar(128),
    @datasets varchar(max) output,
    @comment varchar(512),
    @ownerPRN varchar(64),
    @organismName varchar(128),
    @protCollNameList varchar(4000),
    @protCollOptionsList varchar(256),
    @toolName varchar(64),
    @jobTypeName varchar(64),
    @ModificationDynMetOx varchar(24),
    @ModificationStatCysAlk varchar(24),
    @ModificationDynSTYPhos varchar(24),
    @mode varchar(12) = 'add',            -- 'add', 'preview', or 'debug'
    @message varchar(512) output,
    @callingUser varchar(128) = ''
)
AS
    Set XACT_ABORT, nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Declare @DebugMode tinyint = 0
    Declare @previewMode tinyint = 0

    Begin Try
        ---------------------------------------------------
        --
        ---------------------------------------------------


        If @mode = 'debug'
        Begin --<debug>
            set @message = 'Debug mode; nothing to do'
        End --<debug>

        ---------------------------------------------------
        -- add mode
        ---------------------------------------------------

        If @mode in ('add', 'preview')
        Begin --<add>

            If @mode = 'preview'
                Set @previewMode = 1

            Declare
                @DynMetOxEnabled TINYINT = 0,
                @StatCysAlkEnabled tinyint = 0,
                @DynSTYPhosEnabled tinyint = 0

            SELECT @DynMetOxEnabled =   CASE WHEN @ModificationDynMetOx = 'Yes'    THEN 1 ELSE 0 END
            SELECT @StatCysAlkEnabled = CASE WHEN @ModificationStatCysAlk = 'Yes'  THEN 1 ELSE 0 END
            SELECT @DynSTYPhosEnabled = CASE WHEN @ModificationDynSTYPhos = 'Yes'  THEN 1 ELSE 0 END

            EXEC @myError = CreatePSMJobRequest
                                @requestID = @requestID output,
                                @requestName = @requestName ,
                                @datasets = @datasets output,
                                @toolName = @toolName ,
                                @jobTypeName = @jobTypeName ,
                                @protCollNameList = @protCollNameList ,
                                @protCollOptionsList = @protCollOptionsList ,
                                @DynMetOxEnabled = @DynMetOxEnabled,
                                @StatCysAlkEnabled = @StatCysAlkEnabled,
                                @DynSTYPhosEnabled = @DynSTYPhosEnabled,
                                @comment = @comment ,
                                @ownerPRN = @ownerPRN ,
                                @previewMode = @previewMode,
                                @message = @message  output,
                                @callingUser = @callingUser

        End --<add>

    End Try
    Begin Catch
        EXEC FormatErrorMessage @message output, @myError output

        -- rollback any open transactions
        If (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;

        Exec PostLogEntry 'Error', @message, 'AddJobRequestPSM'
    End Catch

    If @previewMode > 0
    Begin
        -- Use a non-zero error code to assure that the calling page shows the message at the top and bottom of the web page
        -- i.e., make it look like an error occurred, when no error has actually occurred
        -- See https://dms2.pnl.gov/analysis_job_request_psm/create
        return 10
    End

    Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[AddJobRequestPSM] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddJobRequestPSM] TO [DMS_SP_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AddJobRequestPSM] TO [DMS2_SP_User] AS [dbo]
GO
