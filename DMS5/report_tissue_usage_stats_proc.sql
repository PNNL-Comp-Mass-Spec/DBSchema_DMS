/****** Object:  StoredProcedure [dbo].[report_tissue_usage_stats_proc] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[report_tissue_usage_stats_proc]
/****************************************************
**
**  Desc:
**      Generates tissue usage statistics for experiments
**
**      Used by web page https://dms2.pnl.gov/tissue_stats/param
**
**  Auth:   mem
**  Date:   02/20/2024 mem - Initial version
**
*****************************************************/
(
    @startDate varchar(24),                     -- If @instrumentFilterList is empty, filter on experiment creation date.  If @instrumentFilterList is not empty, filter on dataset date
    @endDate varchar(24),
    @campaignIDFilterList varchar(2000) = '',   -- Comma separated list of campaign IDs
    @organismIDFilterList varchar(2000) = '',   -- Comma separated list of organism IDs
    @instrumentFilterList varchar(2000) = '',   -- Comma separated list of instrument names (% and * wild cards are allowed); if empty, dataset stats are not returned
    @message varchar(256) = '' output
)
AS
    Set nocount on

    Declare @myError int = 0
    Declare @myRowCount int = 0

    Set @message = ''

    Exec @myError = report_tissue_usage_stats
                        @startDate            = @startDate,
                        @endDate              = @endDate,
                        @campaignIDFilterList = @campaignIDFilterList,
                        @organismIDFilterList = @organismIDFilterList,
                        @instrumentFilterList = @instrumentFilterList,
                        @message              = @message output

    Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[report_tissue_usage_stats_proc] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[report_tissue_usage_stats_proc] TO [DMS_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[report_tissue_usage_stats_proc] TO [DMS2_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[report_tissue_usage_stats_proc] TO [Limited_Table_Write] AS [dbo]
GO
