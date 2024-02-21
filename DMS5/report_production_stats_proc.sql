/****** Object:  StoredProcedure [dbo].[report_production_stats_proc] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[report_production_stats_proc]
/****************************************************
**
**  Desc:
**      Generates dataset statistics for production instruments
**
**      Used by web page https://dms2.pnl.gov/production_instrument_stats/param
**
**  Auth:   mem
**  Date:   02/20/2024 mem - Initial version
**
*****************************************************/
(
    @startDate varchar(24),
    @endDate varchar(24),
    @productionOnly tinyint = 1,                -- When 0 then shows all instruments; otherwise limits the report to production instruments only
    @campaignIDFilterList varchar(2000) = '',   -- Comma separated list of campaign IDs
    @eusUsageFilterList varchar(2000) = '',     -- Comma separated list of EUS usage types, from table T_EUS_UsageType: CAP_DEV, MAINTENANCE, BROKEN, USER_ONSITE, USER_REMOTE, RESOURCE_OWNER
    @instrumentFilterList varchar(2000) = '',   -- Comma separated list of instrument names (% and * wild cards are allowed)
    @includeProposalType tinyint = 0,           -- When 1, summarize by proposal type
    @message varchar(256) = '' Output
)
AS
    Set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Set @message = ''

    Exec @myError = report_production_stats
                        @startDate            = @startDate,
                        @endDate              = @endDate,
                        @productionOnly       = @productionOnly,
                        @campaignIDFilterList = @campaignIDFilterList,
                        @eusUsageFilterList   = @eusUsageFilterList,
                        @instrumentFilterList = @instrumentFilterList,
                        @includeProposalType  = @includeProposalType,
                        @message              = @message output,
                        @showDebug            = 0

    Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[report_production_stats_proc] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[report_production_stats_proc] TO [DMS_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[report_production_stats_proc] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[report_production_stats_proc] TO [Limited_Table_Write] AS [dbo]
GO
