/****** Object:  StoredProcedure [dbo].[override_dta_gen_for_external_dta] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[override_dta_gen_for_external_dta]
/****************************************************
**
**  Desc:
**    If settings file contains parameter for
**    externally-supplied DTA file,
**    override existing DTA_Gen step to point to it
**
**  Return values: 0: success, otherwise, error code
**
**
**  Auth:   grk
**  Date:   01/28/2008 grk - Initial release (http://prismtrac.pnl.gov/trac/ticket/719)
**          01/30/2009 grk - Modified for extension jobs (http://prismtrac.pnl.gov/trac/ticket/720)
**          03/04/2009 grk - Modified to preset DTA_Gen step to "complete" instead of skipped
**          04/14/2009 grk - Modified to apply to DTA_Import step tool also (Ticket #733, http://prismtrac.pnl.gov/trac/ticket/733)
**          04/15/2009 grk - Modified to maintain shared results for imported DTA (Ticket #733, http://prismtrac.pnl.gov/trac/ticket/733)
**          03/21/2011 mem - Rearranged logic to remove Goto
**          02/16/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @job int,
    @paramsXML xml,
    @message varchar(512) output
)
AS
    set nocount on

    declare @myError int
    set @myError = 0

    declare @myRowCount int
    set @myRowCount = 0

    set @message = ''

    ---------------------------------------------------
    -- get parameter, if present
    ---------------------------------------------------

    declare @externalDTAFolderName varchar(128)
    set @externalDTAFolderName = ''
    --
    SELECT @externalDTAFolderName = xmlNode.value('@Value', 'varchar(64)')
    FROM   @paramsXML.nodes('//Param') AS R(xmlNode)
    WHERE  xmlNode.exist('.[@Name="ExternalDTAFolderName"]') = 1

    If IsNull(@externalDTAFolderName, '') <> ''
    Begin

        ---------------------------------------------------
        -- override DTA_Gen step
        ---------------------------------------------------

        UPDATE #Job_Steps
        SET State = CASE WHEN Step_Tool = 'DTA_Gen'
                         THEN 5
                         ELSE State
                    END,
            Processor = 'Internal',
            Output_Folder_Name = @externalDTAFolderName,
            Input_Folder_Name = 'External'
        WHERE Step_Tool IN ('DTA_Gen', 'DTA_Import') AND
              Job = @Job

    End

    ---------------------------------------------------
    -- Exit
    ---------------------------------------------------
    --
Done:
    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[override_dta_gen_for_external_dta] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[override_dta_gen_for_external_dta] TO [Limited_Table_Write] AS [dbo]
GO
