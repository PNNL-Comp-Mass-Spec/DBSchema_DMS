/****** Object:  UserDefinedFunction [dbo].[ExperimentsFromRequest] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[ExperimentsFromRequest]
/****************************************************
**
**  Desc:
**      returns count of number of experiments made
**      from given sample prep request
**
**
**  Auth:   grk
**  Date:   6/10/2005
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
GRANT VIEW DEFINITION ON [dbo].[ExperimentsFromRequest] TO [DDL_Viewer] AS [dbo]
GO
