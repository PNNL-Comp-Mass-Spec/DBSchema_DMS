/****** Object:  StoredProcedure [dbo].[find_sample_prep_request] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[find_sample_prep_request]
/****************************************************
**
**  Desc:
**      Returns result set of sample prep requests
**      satisfying the search parameters
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**  Auth:   grk
**  Date:   05/15/2006
**          12/20/2006 mem - Now querying V_Find_Sample_Prep_Request using dynamic SQL (Ticket #349)
**          03/14/2014 mem - Expanded @PrepMethod to varchar(512)
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
** Pacific Northwest National Laboratory, Richland, WA
** Copyright 2005, Battelle Memorial Institute
*****************************************************/
(
    @requestID varchar(20) = '',
    @requestName varchar(128) = '',
    @created_After varchar(20) = '',
    @created_Before varchar(20) = '',
    @estComplete_After varchar(20) = '',
    @estComplete_Before varchar(20) = '',
    @priority varchar(20) = '',
    @state varchar(32) = '',
    @reason varchar(512) = '',
    @prepMethod varchar(512) = '',
    @requestedPersonnel varchar(32) = '',
    @assignedPersonnel varchar(256) = '',
    @requester varchar(85) = '',
    @organism varchar(128) = '',
    @biohazardLevel varchar(12) = '',
    @campaign varchar(128) = '',
    @comment varchar(1024) = '',
    @message varchar(512) output
)
AS
    set nocount on

    declare @myError int
    set @myError = 0

    declare @myRowCount int
    set @myRowCount = 0

    set @message = ''


    declare @S varchar(max)
    declare @W varchar(max)

    ---------------------------------------------------
    -- Validate input fields
    ---------------------------------------------------

    -- future: this could get more complicated

    ---------------------------------------------------
    -- Convert input fields
    ---------------------------------------------------

    DECLARE @iRequest_ID int
    SET @iRequest_ID = CONVERT(int, @RequestID)
    --
    DECLARE @iRequest_Name varchar(128)
    SET @iRequest_Name = '%' + @RequestName + '%'
    --
    DECLARE @iCreated_after datetime
    DECLARE @iCreated_before datetime
    SET @iCreated_after = CONVERT(datetime, @Created_After)
    SET @iCreated_before = CONVERT(datetime, @Created_Before)
    --
    DECLARE @iEst_Complete_after datetime
    DECLARE @iEst_Complete_before datetime
    SET @iEst_Complete_after = CONVERT(datetime, @EstComplete_After)
    SET @iEst_Complete_before = CONVERT(datetime, @EstComplete_Before)
    --
    DECLARE @iPriority tinyint
    SET @iPriority = CONVERT(tinyint, @Priority)
    --
    DECLARE @iState varchar(32)
    SET @iState = '%' + @State + '%'
    --
    DECLARE @iReason varchar(512)
    SET @iReason = '%' + @Reason + '%'
    --
    DECLARE @iPrep_Method varchar(128)
    SET @iPrep_Method = '%' + @PrepMethod + '%'
    --
    DECLARE @iRequested_Personnel varchar(32)
    SET @iRequested_Personnel = '%' + @RequestedPersonnel + '%'
    --
    DECLARE @iAssigned_Personnel varchar(256)
    SET @iAssigned_Personnel = '%' + @AssignedPersonnel + '%'
    --
    DECLARE @iRequester varchar(85)
    SET @iRequester = '%' + @Requester + '%'
    --
    DECLARE @iOrganism varchar(128)
    SET @iOrganism = '%' + @Organism + '%'
    --
    DECLARE @iBiohazard_Level varchar(12)
    SET @iBiohazard_Level = '%' + @BiohazardLevel + '%'
    --
    DECLARE @iCampaign varchar(128)
    SET @iCampaign = '%' + @Campaign + '%'
    --
    DECLARE @iComment varchar(1024)
    SET @iComment = '%' + @Comment + '%'
    --

    ---------------------------------------------------
    -- Construct the query
    ---------------------------------------------------
    Set @S = ' SELECT * FROM V_Find_Sample_Prep_Request'

    Set @W = ''
    If Len(@RequestID) > 0
        Set @W = @W + ' AND ([Request_ID] = ' + Convert(varchar(19), @iRequest_ID) + ' )'
    If Len(@RequestName) > 0
        Set @W = @W + ' AND ([Request_Name] LIKE ''' + @iRequest_Name + ''' )'

    If Len(@Created_After) > 0
        Set @W = @W + ' AND ([Created] >= ''' + Convert(varchar(32), @iCreated_after, 121) + ''' )'
    If Len(@Created_Before) > 0
        Set @W = @W + ' AND ([Created] < ''' + Convert(varchar(32), @iCreated_before, 121) + ''' )'
    If Len(@EstComplete_After) > 0
        Set @W = @W + ' AND ([Est_Complete] >= ''' + Convert(varchar(32), @iEst_Complete_after, 121) + ''' )'
    If Len(@EstComplete_Before) > 0
        Set @W = @W + ' AND ([Est_Complete] < ''' + Convert(varchar(32), @iEst_Complete_before, 121) + ''' )'

    If Len(@Priority) > 0
        Set @W = @W + ' AND ([Priority] = ' + Convert(varchar(19), @iPriority) + ' )'
    If Len(@State) > 0
        Set @W = @W + ' AND ([State] LIKE ''' + @iState + ''' )'
    If Len(@Reason) > 0
        Set @W = @W + ' AND ([Reason] LIKE ''' + @iReason + ''' )'

    If Len(@PrepMethod) > 0
        Set @W = @W + ' AND ([Prep_Method] LIKE ''' + @iPrep_Method + ''' )'
    If Len(@RequestedPersonnel) > 0
        Set @W = @W + ' AND ([Requested_Personnel] LIKE ''' + @iRequested_Personnel + ''' )'
    If Len(@AssignedPersonnel) > 0
        Set @W = @W + ' AND ([Assigned_Personnel] LIKE ''' + @iAssigned_Personnel + ''' )'
    If Len(@Requester) > 0
        Set @W = @W + ' AND ([Requester] LIKE ''' + @iRequester + ''' )'
    If Len(@Organism) > 0
        Set @W = @W + ' AND ([Organism] LIKE ''' + @iOrganism + ''' )'
    If Len(@BiohazardLevel) > 0
        Set @W = @W + ' AND ([Biohazard_Level] LIKE ''' + @iBiohazard_Level + ''' )'
    If Len(@Campaign) > 0
        Set @W = @W + ' AND ([Campaign] LIKE ''' + @iCampaign + ''' )'
    If Len(@Comment) > 0
        Set @W = @W + ' AND ([Comment] LIKE ''' + @iComment + ''' )'

    If Len(@W) > 0
    Begin
        -- One or more filters are defined
        -- Remove the first AND from the start of @W and add the word WHERE
        Set @W = 'WHERE ' + Substring(@W, 6, Len(@W) - 5)
        Set @S = @S + ' ' + @W
    End

    ---------------------------------------------------
    -- Run the query
    ---------------------------------------------------
    EXEC (@S)
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount
    --
    if @myError <> 0
    begin
        set @message = 'Error occurred attempting to execute query'
        RAISERROR (@message, 10, 1)
        return 51007
    end

    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[find_sample_prep_request] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[find_sample_prep_request] TO [DMS_Guest] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[find_sample_prep_request] TO [DMS_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[find_sample_prep_request] TO [Limited_Table_Write] AS [dbo]
GO
