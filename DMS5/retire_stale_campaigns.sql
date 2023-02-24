/****** Object:  StoredProcedure [dbo].[RetireStaleCampaigns] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[RetireStaleCampaigns]
/****************************************************
**
**  Desc:
**      Automatically retires (sets inactive) campaigns that have not been used recently
**
**  Auth:   mem
**  Date:   06/11/2022
**
*****************************************************/
(
    @infoOnly tinyint = 1,
    @message varchar(512) = '' output
)
AS
    set nocount on

    Declare @myError Int = 0
    Declare @myRowcount int = 0

    -----------------------------------------------------------
    -- Validate the inputs
    -----------------------------------------------------------

    Set @infoOnly = IsNull(@infoOnly, 1)
    Set @message = ''

    -----------------------------------------------------------
    -- Create a temporary table to track the campaigns to retire
    -----------------------------------------------------------

    CREATE TABLE #Tmp_Campaigns (
        Campaign_ID int not null primary key,
        Campaign varchar(64) Not Null,
        Created Datetime Not Null,
        Most_Recent_Activity Datetime Null,
        Most_Recent_Dataset Datetime Null,
        Most_Recent_Analysis_Job Datetime Null
    )

    -----------------------------------------------------------
    -- Find LC columns that have been used with a dataset, but not in the last 9 months
    -----------------------------------------------------------
    --
    INSERT INTO #Tmp_Campaigns (Campaign_ID, Campaign, Created, Most_Recent_Activity, Most_Recent_Dataset, Most_Recent_Analysis_Job)
    SELECT Campaign_ID,
           Campaign,
           Created,
           Most_Recent_Activity,
           Most_Recent_Dataset,
           Most_Recent_Analysis_Job
    FROM V_Campaign_List_Stale
    WHERE State = 'Active'
    ORDER BY Campaign_ID
    --
    SELECT @myError = @@error, @myRowCount = @@rowcount

    If @infoOnly <> 0
    Begin
        -----------------------------------------------------------
        -- Preview the campaigns that would be retired
        -----------------------------------------------------------
        --
        SELECT *
        FROM #Tmp_Campaigns
        ORDER BY Campaign_ID
    End
    Else
    Begin
        -----------------------------------------------------------
        -- Change the campaign states to 'Inactive'
        -----------------------------------------------------------
        --
        UPDATE T_Campaign
        SET CM_State = 'Inactive'
        WHERE Campaign_ID IN ( SELECT Campaign_ID FROM #Tmp_Campaigns )
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @myRowCount > 0
        Begin
            Set @message = 'Retired ' + Cast(@myRowCount as varchar(12)) + dbo.CheckPlural(@myRowCount, ' campaigns', ' campaigns') + ' that have not been used in at last 18 months and were created over 7 years ago'
            exec PostLogEntry 'Normal', @message, 'RetireStaleCampaigns'
        End
    End

Done:
    Return @myError

GO
