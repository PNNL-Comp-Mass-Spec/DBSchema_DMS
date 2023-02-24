/****** Object:  UserDefinedFunction [dbo].[get_job_request_dataset_name_list] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[get_job_request_dataset_name_list]
/****************************************************
**
**  Desc:
**      Builds a comma separated list of the datasets
**      associated with the given analysis job request
**
**  Auth:   mem
**  Date:   07/30/2019 mem - Initial release
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @requestID int
)
RETURNS varchar(max)
AS
    BEGIN
        Declare @list varchar(max) = null

        SELECT
            @list = Coalesce(@list + ', ', '') + Dataset
        FROM
        (
            SELECT DISTINCT DS.Dataset_Num As Dataset
            FROM T_Analysis_Job_Request_Datasets AJRD
                 INNER JOIN T_Dataset DS
                   ON AJRD.Dataset_ID = DS.Dataset_ID
            WHERE AJRD.Request_ID = @requestID
        ) TX

        If IsNull(@list, '') = ''
            Set @list = '(none)'

        RETURN @list
    END

GO
GRANT VIEW DEFINITION ON [dbo].[get_job_request_dataset_name_list] TO [DDL_Viewer] AS [dbo]
GO
