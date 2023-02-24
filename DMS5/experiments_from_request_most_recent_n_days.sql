/****** Object:  UserDefinedFunction [dbo].[experiments_from_request_most_recent_n_days] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[experiments_from_request_most_recent_n_days]
/****************************************************
**
**  Desc:
**      Returns count of number of experiments made
**      from given sample prep request
**
**      Only includes experiments created within the most recent N days, specified by @days
**
**
**  Auth:   mem
**  Date:   03/26/2013 mem - Initial version
**          01/30/2017 mem - Switch from DateDiff to DateAdd
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @requestID int,
    @days int
)
RETURNS int
AS
    BEGIN
        declare @n int

        SELECT @n = COUNT(*)
        FROM   T_Experiments
        WHERE EX_sample_prep_request_ID = @requestID AND
              EX_created > DateAdd(Day, -ISNULL(@days, 1), GetDate())

        RETURN @n
    END

GO
GRANT VIEW DEFINITION ON [dbo].[experiments_from_request_most_recent_n_days] TO [DDL_Viewer] AS [dbo]
GO
