/****** Object:  UserDefinedFunction [dbo].[GetExperimentGroupList] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[GetExperimentGroupList]
/****************************************************
**
**  Desc:
**  Builds delimited list of experiment group IDs
**  for a given experiment
**
**  Return value: delimited list
**
**  Auth:   mem
**  Date:   12/16/2011 mem
**
*****************************************************/
(
    @ExperimentID int
)
RETURNS varchar(1024)
AS
    BEGIN
        declare @list varchar(1024)
        set @list = ''

        SELECT
            @list = @list + CASE WHEN @list = ''
                                 THEN CONVERT(varchar(12), Group_ID)
                                 ELSE ', ' + CONVERT(varchar(12), Group_ID)
                             END
        FROM T_Experiment_Group_Members
        WHERE (Exp_ID = @ExperimentID)
        ORDER BY Group_ID

        if ISNULL(@list,'') = ''
            Set @list = '(none)'

        RETURN @list
    END

GO
GRANT VIEW DEFINITION ON [dbo].[GetExperimentGroupList] TO [DDL_Viewer] AS [dbo]
GO
