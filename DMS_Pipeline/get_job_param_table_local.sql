/****** Object:  UserDefinedFunction [dbo].[get_job_param_table_local] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[get_job_param_table_local]
/****************************************************
**
**  Desc:   Returns a table of the job parameters stored locally in T_Job_Parameters
**
**  Auth:   grk
**  Date:   06/07/2010
**          04/04/2011 mem - Updated to only query T_Job_Parameters
**          04/11/2022 mem - Use varchar(4000) when populating the table
**          02/16/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @jobNumber INT
)
RETURNS @theTable TABLE (
        Job INT NULL,
        [Name] Varchar(128),
        [Value] Varchar(max)
    )
AS
BEGIN

    ---------------------------------------------------
    -- The following demonstrates how we could Query the XML for a specific parameter:
    --
    -- The XML we are querying looks like:
    -- <Param Section="JobParameters" Name="transferFolderPath" Value="\\proto-9\DMS3_Xfer\"/>
    ---------------------------------------------------
/*

    SELECT @TransferFolderPath = Parameters.query('Param[@Name = "transferFolderPath"]').value('(/Param/@Value)[1]', 'varchar(256)')
    FROM [T_Job_Parameters]
    WHERE Job = @currJob
*/

    ---------------------------------------------------
    -- Query T_Job_Parameters
    ---------------------------------------------------
    --
    INSERT INTO @theTable (Job, [Name], [Value])
    SELECT
        @jobNumber as Job,
--        xmlNode.value('@Section', 'varchar(128)') Section,
        xmlNode.value('@Name', 'varchar(128)') Name,
        xmlNode.value('@Value', 'varchar(4000)') Value
    FROM
        T_Job_Parameters cross apply Parameters.nodes('//Param') AS R(xmlNode)
    WHERE
        T_Job_Parameters.Job = @jobNumber

    RETURN
END

GO
GRANT VIEW DEFINITION ON [dbo].[get_job_param_table_local] TO [DDL_Viewer] AS [dbo]
GO
