/****** Object:  StoredProcedure [dbo].[lookup_instrument_run_info_from_experiment_sample_prep] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[lookup_instrument_run_info_from_experiment_sample_prep]
/****************************************************
**
**  Desc:
**      Get values for instrument related fields from the sample prep request associated with the given experiment (if there is one)
**
**  Return values: 0: success, otherwise, error code
**
**  Arguments:
**    @experimentName       Experiment name
**    @instrumentGroup      Input/output: Instrument group;    if this is '(lookup)', will override with the instrument info from the sample prep request (if found)
**    @datasetType          Input/output: Dataset type;        if this is '(lookup)', will override with the instrument info from the sample prep request (if found)
**    @instrumentSettings   Input/output: Instrument settings; if this is '(lookup)', will be set to 'na'
**    @separationGroup      Input/Output: LC separation group
**    @message              Status message
**
**  Auth:   grk
**  Date:   09/06/2007 grk - Ticket #512 (http://prismtrac.pnl.gov/trac/ticket/512)
**          01/09/2012 grk - Added @secSep
**          03/28/2013 mem - Now returning more explicit error messages when the experiment does not have an associated sample prep request
**          06/10/2014 mem - Now using Instrument_Group in T_Sample_Prep_Request
**          08/20/2014 mem - Switch from Instrument_Name to Instrument_Group
**                         - Rename parameter @instrumentName to @instrumentGroup
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          10/09/2023 mem - Rename parameter @secSep to @separationGroup
**
*****************************************************/
(
    @experimentName varchar(64),
    @instrumentGroup varchar(64) output,
    @datasetType varchar(20) output,
    @instrumentSettings varchar(512) output,
    @separationGroup varchar(64) output,
    @message varchar(512) output
)
AS
    set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Declare @n int

    Set @message = ''

    Declare @ovr varchar(10) = '(lookup)'

    ---------------------------------------------------
    -- Find associated sample prep request for experiment
    ---------------------------------------------------

    Declare @samPrepID int = 0

    SELECT @samPrepID = EX_sample_prep_request_ID
    FROM T_Experiments
    WHERE Experiment_Num = @experimentName
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myError <> 0
    Begin
        Set @message = 'Error trying to find sample prep request for experiment ' + @experimentName + ': ' + Convert(varchar(12), @myError)
        Return @myError
    End

    ---------------------------------------------------
    -- If there is no associated sample prep request
    -- we are done
    ---------------------------------------------------

    If @samPrepID = 0
    Begin
        If @instrumentGroup = @ovr
        Begin
            Set @message = 'Instrument group is set to "' + @ovr + '"; the experiment (' + @experimentName + ') does not have a sample prep request, therefore we cannot auto-define the instrument group.'
            Return 50966
        End
        If @datasetType = @ovr
        Begin
            Set @message = 'Run Type (dataset type) is set to "' + @ovr + '"; the experiment (' + @experimentName + ') does not have a sample prep request, therefore we cannot auto-define the run type.'
            Return 50966
        End

        If @instrumentSettings = @ovr
        Begin
            Set @instrumentSettings = 'na'
        End

        Return 0
    End

    ---------------------------------------------------
    -- Lookup instrument fields from sample prep request
    ---------------------------------------------------

    Declare @prepReqInstrumentGroup varchar(64)
    Declare @prepReqDatasetType varchar(20)
    Declare @prepReqInstrumentSettings varchar(512)
    Declare @prepReqSeparationGroup varchar(64)

    SELECT @prepReqInstrumentGroup = COALESCE(Instrument_Group, Instrument_Name, ''),
           @prepReqDatasetType = ISNULL(Dataset_Type, ''),
           @prepReqInstrumentSettings = ISNULL(Instrument_Analysis_Specifications, ''),
           @prepReqSeparationGroup = ISNULL(Separation_Type, '')
    FROM T_Sample_Prep_Request
    WHERE ID = @samPrepID
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myError <> 0
    Begin
        Set @message = 'Error looking up EUS fields for sample prep request ' + Convert(varchar(12), @samPrepID)
        Return @myError
    End

    ---------------------------------------------------
    -- Handle overrides
    ---------------------------------------------------

    Set @instrumentGroup    = CASE WHEN @instrumentGroup    = @ovr THEN @prepReqInstrumentGroup    ELSE @instrumentGroup END
    Set @datasetType        = CASE WHEN @datasetType        = @ovr THEN @prepReqDatasetType        ELSE @datasetType END
    Set @instrumentSettings = CASE WHEN @instrumentSettings = @ovr THEN @prepReqInstrumentSettings ELSE @instrumentSettings END
    Set @separationGroup    = CASE WHEN @separationGroup    = @ovr THEN @prepReqSeparationGroup    ELSE @separationGroup END

    Return 0

GO
GRANT VIEW DEFINITION ON [dbo].[lookup_instrument_run_info_from_experiment_sample_prep] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[lookup_instrument_run_info_from_experiment_sample_prep] TO [Limited_Table_Write] AS [dbo]
GO
