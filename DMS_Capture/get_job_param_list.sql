/****** Object:  UserDefinedFunction [dbo].[get_job_param_list] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[get_job_param_list]
/****************************************************
**
**  Desc:
**  Builds delimited list of cached parameters for given job
**
**  Return value: delimited list
**
**  Parameters:
**
**  Auth:   grk
**  Date:   01/27/2010
**          02/17/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          03/04/2023 mem - Use new T_Task tables
**
*****************************************************/
(
    @job int
)
RETURNS varchar(8000)
AS
    BEGIN
        declare @list varchar(8000)
        set @list = ''

        -- get parameter xml for job
        --
        SELECT
            @list = '<pre>' + CONVERT(VARCHAR(8000), Parameters) + '</pre>'
        FROM
            T_Task_Parameters
        WHERE
            Job = @job

        -- replace some xml elements with HTML elements
        --
        SET @list = REPLACE(@list, '<param', '')
        SET @list = REPLACE(@list, '/>', '<br>')

/*
        -- for some reason, views that use UDF that use XML don't work from DMS2 web
        --
        SELECT
            @list = CASE WHEN @list = '' THEN '' ELSE @list + ', ' END + param +  ':' + ISNULL(val, '')
        FROM
        (
            SELECT
                xmlNode.value('@Name', 'nvarchar(256)') as param,
                xmlNode.value('@Value', 'nvarchar(4000)') AS val
            FROM
                T_Task_Parameters cross apply Parameters.nodes('//Param') AS R(xmlNode)
            WHERE
                T_Task_Parameters.Job = @job
        ) AS T
*/
        RETURN @list
    END

GO
GRANT VIEW DEFINITION ON [dbo].[get_job_param_list] TO [DDL_Viewer] AS [dbo]
GO
