/****** Object:  StoredProcedure [dbo].[lookup_other_from_experiment_sample_prep] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[lookup_other_from_experiment_sample_prep]
/****************************************************
**
**  Desc:
**      Get values for misc fields from the sample prep
**      Lookup the work package defined for the sample prep request associated with the given experiment (if there is one)
**
**      This procedure is used by add_update_requested_run and the error messages it returns assume that this is the case
**
**  Arguments:
**    @experimentName   Experiment name
**    @workPackage      Input/output: work package provided by the user; will be updated by this procedure if it is '' or '(lookup)' and the experiment has a sample prep request
**    @message          Error message
**
**  Auth:   grk
**  Date:   06/03/2009 grk - Initial release (Ticket #499)
**          01/23/2017 mem - Provide clearer error messages
**          06/13/2017 mem - Fix failure to update @workPackage using sample prep request's work package
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          10/01/2023 mem - Rename variable and update comments
**
*****************************************************/
(
    @experimentName varchar(64),
    @workPackage varchar(50) output,
    @message varchar(512) output
)
AS
    Set XACT_ABORT, nocount on

    Declare @myError int
    Declare @myRowCount int
    Set @myError = 0
    Set @myRowCount = 0

    Declare @n int

    Set @workPackage = LTrim(RTrim(@workPackage))
    Set @message = ''

    Declare @ovr varchar(10) = '(lookup)'

    ---------------------------------------------------
    -- Find associated sample prep request for experiment
    ---------------------------------------------------

    Declare @prepRequestID int = 0

    SELECT @prepRequestID = EX_sample_prep_request_ID
    FROM T_Experiments
    WHERE Experiment_Num = @experimentName
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @myError <> 0
    Begin
        Set @message = 'Error trying to find sample prep request for the experiment'
        Return @myError
    End

    ---------------------------------------------------
    -- If there is no associated sample prep request we are done
    -- However, do not allow the work package to be blank or '(lookup)'
    --
    -- Note that experiments without a sample prep request will have sample_prep_request_id = 0
    ---------------------------------------------------

    If Coalesce(@prepRequestID, 0) = 0
    Begin
        If @workPackage = '' Or @workPackage = @ovr
        Begin
            If Exists (SELECT * FROM T_Experiments WHERE Experiment_Num = @experimentName)
                Set @message = 'Work package cannot be "' + @ovr + '" when the experiment does not have a sample prep request. Please provide a valid work package.'
            Else
                Set @message = 'Unable to change the work package from "' + @ovr + '" ' +
                               'to the one associated with the experiment because the experiment was not found: ' + @experimentName

            Return 50966
        End
        Else
        Begin
            Return 0
        End
    End

    If @workPackage = '' Or @workPackage = @ovr
    Begin
        ---------------------------------------------------
        -- Update the work package using the work package associated with the sample prep request
        ---------------------------------------------------

        Declare @newWorkPackage varchar(50)

        SELECT @newWorkPackage = ISNULL(Work_Package_Number, '')
        FROM T_Sample_Prep_Request
        WHERE ID = @prepRequestID
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
        --
        If @myError <> 0
        Begin
            Set @message = 'Error determining the work package associated with the sample prep request'
            Return @myError
        End

        Set @workPackage = @newWorkPackage
    End

    Return 0

GO
GRANT VIEW DEFINITION ON [dbo].[lookup_other_from_experiment_sample_prep] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[lookup_other_from_experiment_sample_prep] TO [Limited_Table_Write] AS [dbo]
GO
