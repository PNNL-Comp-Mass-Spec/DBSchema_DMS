/****** Object:  UserDefinedFunction [dbo].[experiments_from_request] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[experiments_from_request]
/****************************************************
**
**  Desc:
**      returns count of number of experiments made
**      from given sample prep request
**
**
**  Auth:   grk
**  Date:   6/10/2005
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @requestID int
)
RETURNS int
AS
    BEGIN
        declare @n int
        SELECT     @n = COUNT(*)
        FROM         T_Experiments
        WHERE     (EX_sample_prep_request_ID = @requestID)

        RETURN @n
    END

GO
GRANT VIEW DEFINITION ON [dbo].[experiments_from_request] TO [DDL_Viewer] AS [dbo]
GO
