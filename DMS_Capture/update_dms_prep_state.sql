/****** Object:  StoredProcedure [dbo].[update_dms_prep_state] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[update_dms_prep_state]
/****************************************************
**
**  Desc:
**  Update prep LC state in DMS
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**  Auth:   grk
**  Date:   05/08/2010 grk - Initial Veresion
**          02/17/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          03/04/2023 mem - Use new T_Task tables
**
*****************************************************/
(
    @job INT,
    @script varchar(64),
    @newJobStateInBroker int,
    @message varchar(512) output
)
AS
    set nocount on

    declare @myError int
    declare @myRowCount int
    set @myError = 0
    set @myRowCount = 0

    ---------------------------------------------------
    --
    ---------------------------------------------------
    --
    IF @Script = 'HPLCSequenceCapture'
    BEGIN
        DECLARE @prepLCID INT
        --
        SELECT
            @prepLCID = CONVERT(INT, xmlNode.value('@Value', 'nvarchar(128)'))
        FROM
            T_Task_Parameters cross apply Parameters.nodes('//Param') AS R(xmlNode)
        WHERE
            T_Task_Parameters.Job = @job AND
            (xmlNode.value('@Name', 'nvarchar(128)') = 'ID')

        DECLARE @storagePathID INT
        --
        SELECT
            @storagePathID = CONVERT(INT, xmlNode.value('@Value', 'nvarchar(128)'))
        FROM
            T_Task_Parameters cross apply Parameters.nodes('//Param') AS R(xmlNode)
        WHERE
            T_Task_Parameters.Job = @job AND
            (xmlNode.value('@Name', 'nvarchar(128)') = 'Storage_Path_ID')

        IF @newJobStateInBroker = 3
        BEGIN
            EXEC @myError = s_set_prep_lc_task_complete @prepLCID, @storagePathID, 0, @message OUTPUT
        END

        IF @newJobStateInBroker = 5
        BEGIN
            EXEC @myError = s_set_prep_lc_task_complete @prepLCID, 0, 1, @message output
        END

    END

    return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[update_dms_prep_state] TO [DDL_Viewer] AS [dbo]
GO
