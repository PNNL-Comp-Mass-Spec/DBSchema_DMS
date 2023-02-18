/****** Object:  UserDefinedFunction [dbo].[get_dataset_capture_priority] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[get_dataset_capture_priority]
/****************************************************
**
**  Desc:
**      Determines if the dataset warrants preferential processing priority for dataset capture
**      This procedure is used by make_new_jobs_from_dms to define the capture job priority
**
**      If the dataset name matches one of the filters below, the capture priority will be 2 instead of 4
**      Otherwise, if the instrument group matches one of the filters, the capture priority will be 6 instead of 4
**
**  Return values: 2 if high priority; 4 if medium priority, 6 if low priority
**
**  Auth:   mem
**  Date:   06/27/2019 mem - Initial version
**          02/17/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @datasetName varchar(128),
    @instrumentGroup varchar(64)
)
RETURNS tinyint
AS
BEGIN
    Declare @priority tinyint

    -- These dataset names are modelled after those in GetDatasetPriority in DMS5
    If (@datasetName LIKE 'QC[_][0-9][0-9]%' OR
        @datasetName LIKE 'QC[_-]Shew[_-][0-9][0-9]%' OR
        @datasetName LIKE 'QC[_-]ShewIntact%' OR
        @datasetName LIKE 'QC[_]Shew[_]TEDDY%' OR
        @datasetName LIKE 'QC[_]Mam%' OR
        @datasetName Like 'QC[_]PP[_]MCF-7%'
       ) AND NOT @datasetName LIKE '%-bad'
    Begin
        Set @priority = 2
    End
    Else
    Begin
        If @instrumentGroup In ('TSQ', 'Bruker_FTMS', 'MALDI-Imaging')
        Begin
            Set @priority = 6
        End
        Else
        Begin
            Set @priority = 4
        End
    End

    Return @priority
END

GO
GRANT VIEW DEFINITION ON [dbo].[get_dataset_capture_priority] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[get_dataset_capture_priority] TO [public] AS [dbo]
GO
