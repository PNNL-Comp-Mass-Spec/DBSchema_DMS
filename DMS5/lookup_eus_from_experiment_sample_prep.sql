/****** Object:  StoredProcedure [dbo].[lookup_eus_from_experiment_sample_prep] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[lookup_eus_from_experiment_sample_prep]
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
**          05/25/2021 mem - Change @eusUsageType to USER_REMOTE if the prep request has UsageType USER_REMOTE, even if @eusUsageType is already USER_ONSITE
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          06/16/2023 mem - Change @eusUsageType to RESOURCE_OWNER if the prep request has UsageType RESOURCE_OWNER and @eusUsageType is 'USER', 'USER_ONSITE', or 'USER_REMOTE'
**
*****************************************************/
(
    @experimentName varchar(64),
    @eusUsageType varchar(50) output,       -- If this is "(lookup)", will override with the EUS info from the sample prep request (if found)
    @eusProposalID varchar(10) output,      -- If this is "(lookup)", will override with the EUS info from the sample prep request (if found)
    @eusUsersList varchar(1024) output,     -- If this is "(lookup)", will override with the EUS info from the sample prep request (if found)
    @message varchar(512) output
)
AS
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
    Declare @prepRequestID int = 0
    --
    SELECT @prepRequestID = EX_sample_prep_request_ID
    FROM T_Experiments
    WHERE Experiment_Num = @experimentName
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
      Set @message = 'Error trying to find sample prep request'
      return  @myError
    end

    ---------------------------------------------------
    -- If there is no associated sample prep request
    -- we are done
    ---------------------------------------------------
    --
    if @prepRequestID = 0
    begin
        return  0
    end

    ---------------------------------------------------
    -- Lookup EUS fields from sample prep request
    ---------------------------------------------------

    Declare
        @usageTypeSamplePrep varchar(50),
        @proposalIdSamplePrep varchar(10),
        @userListSamplePrep varchar(1024)

    SELECT @usageTypeSamplePrep = ISNULL(EUS_UsageType, ''),
           @proposalIdSamplePrep = ISNULL(EUS_Proposal_ID, ''),
           @userListSamplePrep = CASE
                      WHEN EUS_User_ID IS NULL THEN ''
                      ELSE Cast(EUS_User_ID AS varchar(12))
                  END
    FROM T_Sample_Prep_Request
    WHERE ID = @prepRequestID
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        Set @message = 'Error looking up EUS fields'
        return  @myError
    end

    ---------------------------------------------------
    -- Handle overrides
    ---------------------------------------------------
    --
    Declare @ovr varchar(10) = '(lookup)'

    Set @eusUsageType = CASE WHEN @eusUsageType = @ovr THEN @usageTypeSamplePrep ELSE @eusUsageType END
    Set @eusProposalID = CASE WHEN @eusProposalID = @ovr THEN @proposalIdSamplePrep ELSE @eusProposalID END
    Set @eusUsersList = CASE WHEN @eusUsersList = @ovr THEN @userListSamplePrep ELSE @eusUsersList End

    If @usageTypeSamplePrep = 'USER_REMOTE' And @eusUsageType In ('USER', 'USER_ONSITE')
    Begin
        Set @message = 'Changed Usage Type to USER_REMOTE based on Prep Request ID ' + Cast(@prepRequestID as varchar(12))
        Set @eusUsageType = 'USER_REMOTE'
    End

    If @usageTypeSamplePrep = 'RESOURCE_OWNER' And @eusUsageType In ('USER', 'USER_ONSITE', 'USER_REMOTE')
    Begin
        Set @message = 'Changed Usage Type to RESOURCE_OWNER based on Prep Request ID ' + Cast(@prepRequestID as varchar(12))
        Set @eusUsageType = 'RESOURCE_OWNER'
    End

GO
GRANT VIEW DEFINITION ON [dbo].[lookup_eus_from_experiment_sample_prep] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[lookup_eus_from_experiment_sample_prep] TO [Limited_Table_Write] AS [dbo]
GO
