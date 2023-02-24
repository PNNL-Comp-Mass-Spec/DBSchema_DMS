/****** Object:  StoredProcedure [dbo].[ReportTissueUsageStats] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[ReportTissueUsageStats]
/****************************************************
**
**  Desc:   Generates tissue usage statistics for experiments
**
**  Auth:   mem
**  Date:   07/23/2019 mem - Initial version
**
*****************************************************/
(
    @startDate varchar(24),                     -- If @instrumentFilterList is empty, filter on experiment creation date.  If @instrumentFilterList is not empty, filter on dataset date
    @endDate varchar(24),
    @campaignIDFilterList varchar(2000) = '',   -- Comma separated list of campaign IDs
    @organismIDFilterList varchar(2000) = '',   -- Comma separate list of organism IDs
    @instrumentFilterList varchar(2000) = '',   -- Comma separated list of instrument names (% and * wild cards are allowed); if empty, dataset stats are not returned
    @message varchar(256) = '' output
)
AS
    Set XACT_ABORT, nocount on

    Declare @myRowCount int = 0
    Declare @myError int = 0
    Declare @result int

    Declare @stDate datetime
    Declare @eDate datetime

    Declare @msg varchar(256)
    Declare @nullDate Datetime = Null

    Declare @logErrors tinyint = 1

    BEGIN TRY

    --------------------------------------------------------------------
    -- Validate the inputs
    --------------------------------------------------------------------
    --
    Set @campaignIDFilterList = LTrim(RTrim(IsNull(@campaignIDFilterList, '')))
    Set @organismIDFilterList = LTrim(RTrim(IsNull(@organismIDFilterList, '')))
    Set @instrumentFilterList = LTrim(RTrim(IsNull(@instrumentFilterList, '')))

    Set @message = ''

    --------------------------------------------------------------------
    -- Populate a temporary table with the Campaign IDs to filter on
    --------------------------------------------------------------------
    --
    CREATE TABLE #Tmp_CampaignFilter (
        Campaign_ID int NOT NULL,
        Fraction_EMSL_Funded float NULL
    )

    CREATE UNIQUE CLUSTERED INDEX #IX_Tmp_CampaignFilter ON #Tmp_CampaignFilter (Campaign_ID)

    Exec @result = PopulateCampaignFilterTable @campaignIDFilterList, @message=@message output

    If @result <> 0
    Begin
        Set @logErrors = 0
        RAISERROR (@message, 11, 15)
    End

    --------------------------------------------------------------------
    -- Populate a temporary table with the Instrument IDs to filter on
    --------------------------------------------------------------------
    --
    CREATE TABLE #Tmp_InstrumentFilter (
        Instrument_ID int NOT NULL
    )

    CREATE UNIQUE CLUSTERED INDEX #IX_Tmp_InstrumentFilter ON #Tmp_InstrumentFilter (Instrument_ID)

    If Len(@instrumentFilterList) > 0
    Begin
        Exec @result = PopulateInstrumentFilterTable @instrumentFilterList, @message=@message output

        If @result <> 0
        Begin
            Set @logErrors = 0
            RAISERROR (@message, 11, 15)
        End
    End

    --------------------------------------------------------------------
    -- Populate a temporary table with the organisms to filter on
    --------------------------------------------------------------------
    --
    CREATE TABLE #Tmp_OrganismFilter (
        Organism_ID int NOT NULL,
        Organism_Name varchar(128) NULL
    )

    CREATE CLUSTERED INDEX #IX_Tmp_OrganismFilter ON #Tmp_OrganismFilter (Organism_ID)

    If @organismIDFilterList <> ''
    Begin
        INSERT INTO #Tmp_OrganismFilter (Organism_ID)
        SELECT DISTINCT Value
        FROM dbo.udfParseDelimitedIntegerList(@organismIDFilterList, ',')
        ORDER BY Value

        -- Look for invalid Organism ID values
        Set @msg = ''
        SELECT @msg = Convert(varchar(12), OrgFilter.Organism_ID) + ',' + @msg
        FROM #Tmp_OrganismFilter OrgFilter
             LEFT OUTER JOIN T_Organisms Org
               ON OrgFilter.Organism_ID = Org.Organism_ID
        WHERE Org.Organism_ID IS NULL
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @myRowCount > 0
        Begin
            -- Remove the trailing comma
            Set @message = Substring(@msg, 1, Len(@msg)-1)

            If @myRowCount = 1
                set @msg = 'Invalid Organism ID: ' + @msg
            Else
                set @msg = 'Invalid Organism IDs: ' + @msg

            Set @logErrors = 0
            RAISERROR (@msg, 11, 15)
        End
    End
    Else
    Begin
        INSERT INTO #Tmp_OrganismFilter (Organism_ID, Organism_Name)
        SELECT Organism_ID, OG_Name
        FROM T_Organisms
        ORDER BY Organism_ID
    End

    --------------------------------------------------------------------
    -- Determine the start and end dates
    --------------------------------------------------------------------

    Exec @result = ResolveStartAndEndDates @startDate, @endDate, @stDate Output, @eDate Output, @message=@message output

    If @result <> 0
    Begin
        Set @logErrors = 0
        RAISERROR (@message, 11, 15)
    End

    ---------------------------------------------------
    -- Generate the report
    ---------------------------------------------------

    If Len(@instrumentFilterList) > 0
    Begin
        -- Filter on instrument and use dataset acq times for the date filter

        If Not Exists (Select * From #Tmp_InstrumentFilter)
        Begin
            SELECT '' AS Tissue_ID,
                   '' AS Tissue,
                   0 AS Experiments,
                   0 AS Datasets,
                   0 AS Instruments,
                   'Warning' AS Instrument_First,
                   'No instruments matched the instrument name filter' AS Instrument_Last,
                   @nullDate AS Dataset_Acq_Time_Min,
                   @nullDate AS Dataset_Acq_Time_Max,
                   '' AS Organism_First,
                   '' AS Organism_Last,
                   '' AS Campaign_First,
                   '' AS Campaign_Last
        End
        Else
        Begin
            SELECT E.EX_Tissue_ID AS Tissue_ID,
                   BTO.Tissue AS Tissue,
                   Count(DISTINCT E.Exp_ID) AS Experiments,
                   Count(DISTINCT D.Dataset_ID) AS Datasets,
                   Count(DISTINCT InstName.Instrument_ID) AS Instruments,
                   Min(InstName.IN_name) AS Instrument_First,
                   Max(InstName.IN_name) AS Instrument_Last,
                   Min(ISNULL(D.Acq_Time_Start, D.DS_created)) AS Dataset_Acq_Time_Min,
                   Max(ISNULL(D.Acq_Time_Start, D.DS_created)) AS Dataset_Acq_Time_Max,
                   Min(Org.OG_name) AS Organism_First,
                   Max(Org.OG_name) AS Organism_Last,
                   Min(C.Campaign_Num) AS Campaign_First,
                   Max(C.Campaign_Num) AS Campaign_Last
            FROM T_Dataset D
                 INNER JOIN T_Experiments E
                   ON E.Exp_ID = D.Exp_ID
                 INNER JOIN T_Instrument_Name InstName
                   ON D.DS_instrument_name_ID = InstName.Instrument_ID
                 INNER JOIN #Tmp_InstrumentFilter InstFilter
                   ON D.DS_Instrument_Name_ID = InstFilter.Instrument_ID
                 INNER JOIN #Tmp_CampaignFilter CampaignFilter
                   ON E.EX_campaign_ID = CampaignFilter.Campaign_ID
                 INNER JOIN #Tmp_OrganismFilter OrgFilter
                   ON E.EX_organism_ID = OrgFilter.Organism_ID
                 INNER JOIN dbo.T_Campaign C
                   ON E.EX_campaign_ID = C.Campaign_ID
                 INNER JOIN dbo.T_Organisms Org
                   ON E.EX_organism_ID = Org.Organism_ID
                 LEFT OUTER JOIN S_V_BTO_ID_to_Name BTO
                   ON E.EX_Tissue_ID = BTO.Identifier
            WHERE ISNULL(D.Acq_Time_Start, D.DS_created) BETWEEN @stDate AND @eDate
            GROUP BY EX_Tissue_ID, BTO.Tissue
            --
            SELECT @myError = @@error, @myRowCount = @@rowcount
        End
    End
    Else
    Begin
        -- Use experiment creation time for the date filter

        SELECT E.EX_Tissue_ID AS Tissue_ID,
               BTO.Tissue,
               Count(E.Exp_ID) AS Experiments,
               Min(E.EX_created) AS Exp_Created_Min,
               Max(E.EX_created) AS Exp_Created_Max,
               Min(Org.OG_name) AS Organism_First,
               Max(Org.OG_name) AS Organism_Last,
               Min(C.Campaign_Num) AS Campaign_First,
               Max(C.Campaign_Num) AS Campaign_Last
        FROM T_Experiments E
             INNER JOIN #Tmp_CampaignFilter CampaignFilter
               ON E.EX_campaign_ID = CampaignFilter.Campaign_ID
             INNER JOIN #Tmp_OrganismFilter OrgFilter
               ON E.EX_organism_ID = OrgFilter.Organism_ID
             INNER JOIN dbo.T_Campaign C
               ON E.EX_campaign_ID = C.Campaign_ID
             INNER JOIN dbo.T_Organisms Org
               ON E.EX_organism_ID = Org.Organism_ID
             LEFT OUTER JOIN S_V_BTO_ID_to_Name BTO
               ON E.EX_Tissue_ID = BTO.Identifier
        WHERE E.EX_created BETWEEN @stDate AND @eDate
        GROUP BY EX_Tissue_ID, BTO.Tissue
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

    End

    END TRY
    BEGIN CATCH
        EXEC FormatErrorMessage @message output, @myError output

        -- rollback any open transactions
        IF (XACT_STATE()) <> 0
            ROLLBACK TRANSACTION;

        If @logErrors > 0
        Begin
            Exec PostLogEntry 'Error', @message, 'ReportTissueUsageStats'
        End
    END CATCH

    RETURN @myError

GO
GRANT VIEW DEFINITION ON [dbo].[ReportTissueUsageStats] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[ReportTissueUsageStats] TO [DMS_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[ReportTissueUsageStats] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[ReportTissueUsageStats] TO [Limited_Table_Write] AS [dbo]
GO
