/****** Object:  StoredProcedure [dbo].[lookup_instrument_run_info_from_experiment_sample_prep] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[lookup_instrument_run_info_from_experiment_sample_prep]
/****************************************************
**
**  Desc:
**    Get values for instrument related fields
**    from the sample prep request associated with
**    the given experiment (if there is one)
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**  Auth:   grk
**  Date:   09/06/2007 (Ticket #512 http://prismtrac.pnl.gov/trac/ticket/512)
**          01/09/2012 grk - added @secSep
**          03/28/2013 mem - Now returning more explicit error messages when the experiment does not have an associated sample prep request
**          06/10/2014 mem - Now using Instrument_Group in T_Sample_Prep_Request
**          08/20/2014 mem - Switched from Instrument_Name to Instrument_Group
**                         - Renamed parameter @instrumentName to @instrumentGroup
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @experimentName varchar(64),
    @instrumentGroup varchar(64) output,
    @datasetType varchar(20) output,
    @instrumentSettings varchar(512) output,
    @secSep varchar(64) output,
    @message varchar(512) output
)
AS
    set nocount on

    declare @myError int
    set @myError = 0

    declare @myRowCount int
    set @myRowCount = 0

    declare @n int

    set @message = ''

    declare @ovr varchar(10) = '(lookup)'

    ---------------------------------------------------
    -- Find associated sample prep request for experiment
    ---------------------------------------------------
    declare @samPrepID int
    set @samPrepID = 0
    --
    SELECT @samPrepID = EX_sample_prep_request_ID
    FROM T_Experiments
    WHERE Experiment_Num = @experimentName
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
      set @message = 'Error trying to find sample prep request for experiment ' + @experimentName + ': ' + Convert(varchar(12), @myError)
      return @myError
    end

    ---------------------------------------------------
    -- If there is no associated sample prep request
    -- we are done
    ---------------------------------------------------
    if @samPrepID = 0
    begin
        if (@instrumentGroup = @ovr)
        begin
            set @message = 'Instrument group is set to "' + @ovr + '"; the experiment (' + @experimentName + ') does not have a sample prep request, therefore we cannot auto-define the instrument group.'
            return 50966
        end
        if (@DatasetType = @ovr)
        begin
            set @message = 'Run Type (Dataset Type) is set to "' + @ovr + '"; the experiment (' + @experimentName + ') does not have a sample prep request, therefore we cannot auto-define the run type.'
            return 50966
        end

        if (@instrumentSettings = @ovr)
        begin
            set @instrumentSettings = 'na'
        end

        return  0
    end

    ---------------------------------------------------
    -- Lookup instrument fields from sample prep request
    ---------------------------------------------------

    Declare
        @irInstGroup varchar(64),
        @irDSType varchar(20),
        @irInstSettings varchar(512),
        @irSecSep varchar(64)

    SELECT
        @irInstGroup = COALESCE(Instrument_Group, Instrument_Name, ''),
        @irDSType = ISNULL(Dataset_Type, ''),
        @irInstSettings = ISNULL(Instrument_Analysis_Specifications, ''),
        @irSecSep = ISNULL(Separation_Type, '')
    FROM
        T_Sample_Prep_Request
    WHERE
        (ID = @samPrepID)
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
      set @message = 'Error looking up EUS fields for sample prep request ' + Convert(varchar(12), @samPrepID)
      return  @myError
    end

    ---------------------------------------------------
    -- handle overrides
    --
    ---------------------------------------------------
    set @instrumentGroup = CASE WHEN @instrumentGroup = @ovr THEN @irInstGroup ELSE @instrumentGroup END
    set @DatasetType = CASE WHEN @DatasetType = @ovr THEN @irDSType ELSE @DatasetType END
    set @instrumentSettings = CASE WHEN @instrumentSettings = @ovr THEN @irInstSettings ELSE @instrumentSettings END
    set @secSep = CASE WHEN @secSep = @ovr THEN @irSecSep ELSE @secSep END

    return 0

GO
GRANT VIEW DEFINITION ON [dbo].[lookup_instrument_run_info_from_experiment_sample_prep] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[lookup_instrument_run_info_from_experiment_sample_prep] TO [Limited_Table_Write] AS [dbo]
GO
