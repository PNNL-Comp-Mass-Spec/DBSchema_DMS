/****** Object:  StoredProcedure [dbo].[LookupEUSFromExperimentSamplePrep] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[LookupEUSFromExperimentSamplePrep]
/****************************************************
**
**  Desc: 
**      Get values for EUS field from the sample prep request
**      associated with the given experiment (if there is one) 
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   grk
**  Date:   07/11/2007 grk - Ticket #499
**          07/16/2007 grk - Added check for "(lookup)"
**          08/02/2018 mem - T_Sample_Prep_Request now tracks EUS User ID as an integer
**
*****************************************************/
(
    @experimentNum varchar(64),
    @eusUsageType varchar(50) output,       -- If this is "(lookup)", will override with the EUS info from the sample prep request (if found)
    @eusProposalID varchar(10) output,      -- If this is "(lookup)", will override with the EUS info from the sample prep request (if found)
    @eusUsersList varchar(1024) output,     -- If this is "(lookup)", will override with the EUS info from the sample prep request (if found)
    @message varchar(512) output
)
As
    set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0
    
    Set @message = ''

    Set @eusUsageType = Ltrim(Rtrim(IsNull(@eusUsageType, '')))
    Set @eusProposalID = Ltrim(Rtrim(IsNull(@eusProposalID, '')))
    Set @eusUsersList = Ltrim(Rtrim(IsNull(@eusUsersList, '')))
    
    ---------------------------------------------------
    -- Find associated sample prep request for experiment
    ---------------------------------------------------
    --
    Declare @requestID int = 0
    --
    SELECT @requestID = EX_sample_prep_request_ID
    FROM T_Experiments
    WHERE Experiment_Num = @experimentNum
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
      set @message = 'Error trying to find sample prep request'
      return  @myError
    end

    ---------------------------------------------------
    -- If there is no associated sample prep request
    -- we are done
    ---------------------------------------------------
    --
    if @requestID = 0
    begin
        return  0
    end

    ---------------------------------------------------
    -- Lookup EUS fields from sample prep request
    ---------------------------------------------------

    Declare
        @eUT varchar(50),
        @ePID varchar(10),
        @eUL varchar(1024)

    SELECT @eUT = ISNULL(EUS_UsageType, ''),
           @ePID = ISNULL(EUS_Proposal_ID, ''),
           @eUL = CASE
                      WHEN EUS_User_ID IS NULL THEN ''
                      ELSE Cast(EUS_User_ID AS varchar(12))
                  END
    FROM T_Sample_Prep_Request
    WHERE ID = @requestID
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        set @message = 'Error looking up EUS fields'
        return  @myError
    end

    ---------------------------------------------------
    -- Handle overrides
    ---------------------------------------------------
    --
    Declare @ovr varchar(10) = '(lookup)'

    set @eusUsageType = CASE WHEN @eusUsageType = @ovr THEN @eUT ELSE @eusUsageType END
    set @eusProposalID = CASE WHEN @eusProposalID = @ovr THEN @ePID ELSE @eusProposalID END
    set @eusUsersList = CASE WHEN @eusUsersList = @ovr THEN @eUL ELSE @eusUsersList END

GO
GRANT VIEW DEFINITION ON [dbo].[LookupEUSFromExperimentSamplePrep] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[LookupEUSFromExperimentSamplePrep] TO [Limited_Table_Write] AS [dbo]
GO
