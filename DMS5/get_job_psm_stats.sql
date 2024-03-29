/****** Object:  UserDefinedFunction [dbo].[get_job_psm_stats] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[get_job_psm_stats]
/****************************************************
**
**  Desc:
**  Builds delimited list of PSM stats for given analysis job
**
**  Return value: delimited list
**
**  Parameters:
**
**  Auth:   mem
**  Date:   02/22/2012 mem - Initial version
**          05/08/2012 mem - Now showing FDR-based stats if Total_PSMs_FDR_Filter > 0
**          05/11/2012 mem - Now displaying FDR as a percentage
**          01/17/2014 mem - Added support for MSGF_Threshold_Is_EValue = 1
**          07/15/2020 mem - Report % PSMs without TMT or iTRAQ
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @job int
)
RETURNS varchar(2000)
AS
    BEGIN
        declare @stats varchar(2000)

        Set @stats = ''

        SELECT @stats =
                 CASE WHEN Total_PSMs_FDR_Filter > 0 THEN
                   'Spectra Searched: ' + CONVERT(varchar(12), Spectra_Searched) + ', ' +
                   'Total PSMs: ' +       CONVERT(varchar(12), Total_PSMs_FDR_Filter) +
                   CASE WHEN Dynamic_Reporter_Ion > 0
                        THEN ' (' + CONVERT(VARCHAR(12), Percent_PSMs_Missing_NTermReporterIon) + '% missing N-Terminal reporter ion), '
                        ELSE ', '
                   END +
                   'Unique Peptides: ' +  CONVERT(varchar(12), Unique_Peptides_FDR_Filter) + ', ' +
                   'Unique Proteins: ' +  CONVERT(varchar(12), Unique_Proteins_FDR_Filter) +
                   '  (FDR < ' + CONVERT(varchar(12), Convert(decimal(9,2), FDR_Threshold*100.0)) + '%)'
                 ELSE
                   'Spectra Searched: ' + CONVERT(varchar(12), Spectra_Searched) + ', ' +
                   'Total PSMs: ' +       CONVERT(varchar(12), Total_PSMs) + ', ' +
                   'Unique Peptides: ' +  CONVERT(varchar(12), Unique_Peptides) + ', ' +
                   'Unique Proteins: ' +  CONVERT(varchar(12), Unique_Proteins) +
                   '  (' + CASE WHEN MSGF_Threshold_Is_EValue > 0 THEN 'EValue' ELSE 'MSGF' END + ' < ' + CONVERT(varchar(12), MSGF_Threshold) + ')'
                 END
        FROM T_Analysis_Job_PSM_Stats
        WHERE (Job = @Job)

        RETURN @stats
    END

GO
GRANT VIEW DEFINITION ON [dbo].[get_job_psm_stats] TO [DDL_Viewer] AS [dbo]
GO
