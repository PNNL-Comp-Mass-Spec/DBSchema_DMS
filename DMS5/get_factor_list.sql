/****** Object:  UserDefinedFunction [dbo].[GetFactorList] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[GetFactorList]
/****************************************************
**
**  Desc:
**  Builds a delimited list of factors
**  (as name/value pairs) for given
**  requested run
**
**  Return value: delimited list
**
**  Parameters:
**
**  Auth:   grk
**  Date:   05/17/2011
**
*****************************************************/
(
    @requestID INT
)
RETURNS VARCHAR(256)
AS
    BEGIN
        DECLARE @list VARCHAR(256)
        SET @list = ''

        IF NOT @requestID IS NULL
        BEGIN
            SELECT  @list = @list + CASE WHEN @list = '' THEN '' ELSE ', ' END + [Name] + ':' + [Value]
            FROM    T_Factor F
            WHERE   ( TYPE = 'Run_Request' )
                    AND ( TargetID = @requestID )
            ORDER BY [Name]
        END

        RETURN @list
    END
GO
GRANT VIEW DEFINITION ON [dbo].[GetFactorList] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[GetFactorList] TO [DMS_User] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[GetFactorList] TO [DMS2_SP_User] AS [dbo]
GO
