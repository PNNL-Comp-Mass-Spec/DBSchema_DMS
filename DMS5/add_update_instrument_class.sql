/****** Object:  StoredProcedure [dbo].[add_update_instrument_class] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[add_update_instrument_class]
/****************************************************
**
**  Desc:   Updates existing Instrument Class in database
**
**  Arguments:
**    @instrumentClass  Instrument class name
**    @isPurgeable      1 if datasets can be purged for this instrument class, 0 if purging is disabled
**    @rawDataType      Instrument data type; see table T_Instrument_Data_Type_Name
**    @params           XML parameters with DatasetQC options (see below)
**    @comment          Instrument class comment
**    @mode             The only valid mode is 'update', since 'add' is not allowed in this procedure; instead directly edit table T_Instrument_Class
**
**  Example value for @params
**
**      <sections>
**        <section name="DatasetQC">
**          <item key="SaveTICAndBPIPlots" value="True" />
**          <item key="SaveLCMS2DPlots" value="True" />
**          <item key="ComputeOverallQualityScores" value="True" />
**          <item key="CreateDatasetInfoFile" value="True" />
**          <item key="LCMS2DPlotMZResolution" value="0.4" />
**          <item key="LCMS2DPlotMaxPointsToPlot" value="200000" />
**          <item key="LCMS2DPlotMinPointsPerSpectrum" value="2" />
**          <item key="LCMS2DPlotMinIntensity" value="0" />
**          <item key="LCMS2DOverviewPlotDivisor" value="10" />
**        </section>
**      </sections>
**
**  Auth:   jds
**  Date:   07/06/2006
**          07/25/2007 mem - Added parameter @allowedDatasetTypes
**          09/17/2009 mem - Removed parameter @allowedDatasetTypes (Ticket #748)
**          06/21/2010 mem - Added parameter @params
**          11/16/2010 mem - Added parameter @comment
**          06/16/2017 mem - Restrict access using verify_sp_authorized
**          08/01/2017 mem - Use THROW if not authorized
**          12/06/2018 mem - Add try/catch handling and disallow @mode = 'add'
**          02/01/2023 mem - Rename argument to @isPurgeable and switch from text to int
**                         - Remove argument @requiresPreparation
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @instrumentClass varchar(32),
    @isPurgeable tinyint,
    @rawDataType varchar(32),
    @params text,
    @comment varchar(255),
    @mode varchar(12) = 'update',       -- Note that 'add' is not allowed in this procedure; instead directly edit table T_Instrument_Class
    @message varchar(512) output
)
AS
    Set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Declare @msg varchar(256)

    Declare @xmlParams xml

    Set @message = ''

    Declare @logErrors tinyint = 0

    ---------------------------------------------------
    -- Verify that the user can execute this procedure from the given client host
    ---------------------------------------------------

    Declare @authorized tinyint = 0
    Exec @authorized = verify_sp_authorized 'add_update_instrument_class', @raiseError = 1
    If @authorized = 0
    Begin;
        THROW 51000, 'Access denied', 1;
    End;

    BEGIN TRY

    ---------------------------------------------------
    -- Validate input fields
    ---------------------------------------------------

    If LEN(@instrumentClass) < 1
    Begin;
        THROW 51000, 'Instrument Class Name cannot be blank', 1;
    End;

    If @isPurgeable Is Null
    Begin;
        THROW 51001, 'Is Purgeable cannot be null', 1;
    End;

    If LEN(@rawDataType) < 1
    Begin;
        THROW 51002, 'Raw Data Type cannot be blank', 1;
    End;

    If @myError <> 0
        return @myError


    Set @params = IsNull(@params, '')
    If DataLength(@params) > 0
    Begin
        Set @xmlParams = Try_Cast(@params As Xml)
        If @xmlParams Is Null
        Begin;
            Set @message = 'Could not convert Params to XML';
            THROW 51004, @message, 1;
        End;
    End

    ---------------------------------------------------
    -- Note: the add mode is not enabled in this stored procedure
    ---------------------------------------------------
    If @mode = 'add'
    Begin;
        THROW 51005, 'The "add" instrument class mode is disabled for this page; instead directly edit table T_Instrument_Class', 1;
    End;

    ---------------------------------------------------
    -- action for update mode
    ---------------------------------------------------
    --
    If @mode = 'update'
    Begin
        Set @logErrors = 1

        UPDATE T_Instrument_Class
        SET
            is_purgable = @isPurgeable,
            raw_data_type = @rawDataType,
            Params = @xmlParams,
            Comment = @comment
        WHERE IN_class = @instrumentClass;

        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
        Begin;
            Set @message = 'Update operation failed: "' + @instrumentClass + '"';
            THROW 51004, @message, 1;
            return 51004
        End;

    End -- update mode

    END Try
    BEGIN CATCH
        EXEC format_error_message @message output, @myError Output

        -- Rollback any open transactions
        IF (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;

        If @logErrors > 0
        Begin
            Declare @logMessage varchar(1024) = @message + '; Instrument class ' + @instrumentClass
            exec post_log_entry 'Error', @logMessage, 'add_update_instrument_class'
        End

    END Catch

    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[add_update_instrument_class] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[add_update_instrument_class] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[add_update_instrument_class] TO [Limited_Table_Write] AS [dbo]
GO
