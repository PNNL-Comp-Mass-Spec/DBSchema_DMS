/****** Object:  UserDefinedFunction [dbo].[get_dataset_priority] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[get_dataset_priority]
/****************************************************
**
**  Desc:
**       Determines if the dataset name warrants preferential processing priority
**       This procedure is used by AddNewDataset to auto-release QC_Shew datasets
**
**       If either the dataset name or the experiment name matches one of the
**       filters below, the Interest_Rating is set to 5 (Released)
**
**  Return values: 1 if highest priority; 3 if medium priority, 5 if low priority
**                 0 to use the default priority
**
**  Auth:   grk
**  Date:   02/10/2006
**          04/09/2007 mem - Added matching of QC_Shew datasets in addition to QC datasets (Ticket #430)
**          04/11/2008 mem - Added matching of SE_QC_Shew datasets in addition to QC datasets
**          05/12/2011 mem - Now excluding datasets that end in -bad
**          01/16/2014 mem - Added QC_ShewIntact datasets
**          12/18/2014 mem - Replace [_] with [_-]
**          05/07/2015 mem - Added QC_Shew_TEDDY
**          08/08/2018 mem - Added QC_Mam and QC_PP_MCF-7
**          06/27/2019 mem - Renamed from DatasetPreference to get_dataset_priority
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @datasetName varchar(128)
)
RETURNS tinyint
AS
BEGIN
    Declare @result tinyint

    If (@datasetName LIKE 'QC[_][0-9][0-9]%' OR
        @datasetName LIKE 'QC[_-]Shew[_-][0-9][0-9]%' OR
        @datasetName LIKE 'QC[_-]ShewIntact%' OR
        @datasetName LIKE 'QC[_]Shew[_]TEDDY%' OR
        @datasetName LIKE 'QC[_]Mam%' OR
        @datasetName Like 'QC[_]PP[_]MCF-7%'
       ) AND NOT @datasetName LIKE '%-bad'
    Begin
        Set @result = 1
    End
    Else
    Begin
        Set @result = 0
    End

    Return @result
END

GO
GRANT VIEW DEFINITION ON [dbo].[get_dataset_priority] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[get_dataset_priority] TO [public] AS [dbo]
GO
