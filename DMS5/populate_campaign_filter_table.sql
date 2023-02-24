/****** Object:  StoredProcedure [dbo].[populate_campaign_filter_table] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[populate_campaign_filter_table]
/****************************************************
**
**  Desc:   Populates temp table #Tmp_CampaignFilter
**          based on the comma-separated campaign IDs in @campaignIDFilterList
**
**  The calling procedure must create the temporary table:
**    CREATE TABLE #Tmp_CampaignFilter (
**        Campaign_ID int NOT NULL,
**        Fraction_EMSL_Funded float NULL
**    )
**
**  Return values: 0: success, otherwise, error code
**
**  Date:   07/22/2019 mem - Initial version
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @campaignIDFilterList varchar(2000) = '',   -- Comma separated list of campaign IDs
    @message varchar(512) = '' output
)
AS
    Set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Declare @msg varchar(512)

    Set @campaignIDFilterList = Ltrim(Rtrim(IsNull(@campaignIDFilterList, '')))
    Set @message = ''

    If @campaignIDFilterList <> ''
    Begin
        INSERT INTO #Tmp_CampaignFilter (Campaign_ID)
        SELECT DISTINCT Value
        FROM dbo.parse_delimited_integer_list(@campaignIDFilterList, ',')
        ORDER BY Value

        -- Look for invalid Campaign ID values
        Set @msg = ''
        SELECT @msg = Convert(varchar(12), CF.Campaign_ID) + ',' + @msg
        FROM #Tmp_CampaignFilter CF
             LEFT OUTER JOIN T_Campaign C
               ON CF.Campaign_ID = C.Campaign_ID
        WHERE C.Campaign_ID IS NULL
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @myRowCount > 0
        Begin
            -- Remove the trailing comma
            Set @msg = Substring(@msg, 1, Len(@msg)-1)

            If @myRowCount = 1
                set @msg = 'Invalid Campaign ID: ' + @msg
            Else
                set @msg = 'Invalid Campaign IDs: ' + @msg

            Set @message = @msg
            Return 56000
        End

    End
    Else
    Begin
        INSERT INTO #Tmp_CampaignFilter (Campaign_ID)
        SELECT Campaign_ID
        FROM T_Campaign
        ORDER BY Campaign_ID
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount
    End

    -----------------------------------------------------------
    -- Exit
    -----------------------------------------------------------
Done:
    return @myError

GO
