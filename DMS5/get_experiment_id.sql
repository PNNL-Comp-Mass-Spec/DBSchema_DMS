/****** Object:  UserDefinedFunction [dbo].[get_experiment_id] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[get_experiment_id]
/****************************************************
**
**  Desc: Gets experiment ID for given experiment name
**
**  Return values: 0: failure, otherwise, experiment ID
**
**  Auth:   grk
**  Date:   01/26/2001
**          08/03/2017 mem - Add Set NoCount On
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @experimentName varchar(64) = " "
)
RETURNS int
AS
BEGIN
    Declare @experimentID int = 0

    SELECT @experimentID = Exp_ID
    FROM T_Experiments
    WHERE Experiment_Num = @experimentName

    return @experimentID
END

GO
GRANT VIEW DEFINITION ON [dbo].[get_experiment_id] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[get_experiment_id] TO [DMS_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[get_experiment_id] TO [Limited_Table_Write] AS [dbo]
GO
