/****** Object:  UserDefinedFunction [dbo].[get_batch_requested_run_list] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[get_batch_requested_run_list]
/****************************************************
**
**  Desc:
**      Builds delimited list of requested runs
**      associated with the given batch
**
**  Return value: delimited list
**
**  Parameters:
**
**  Auth:   grk
**  Date:   01/11/2006 grk - Initial version
**          03/29/2019 mem - Return an empty string when @batchID is 0 (meaning "unassigned", no batch)
**          06/02/2021 mem - Expand the return value to varchar(max)
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @batchID int
)
RETURNS varchar(max)
AS
BEGIN
    Declare @list varchar(max) = ''

    SELECT @list = @list + CASE
                               WHEN @list = '' THEN cast(ID as varchar(12))
                               ELSE ', ' + cast(ID as varchar(12))
                           END
    FROM T_Requested_Run
    WHERE RDS_BatchID = @batchID AND RDS_BatchID <> 0
    ORDER BY ID

    RETURN @list
END

GO
GRANT VIEW DEFINITION ON [dbo].[get_batch_requested_run_list] TO [DDL_Viewer] AS [dbo]
GO
