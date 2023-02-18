/****** Object:  StoredProcedure [dbo].[disable_archive_dependent_managers] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[disable_archive_dependent_managers]
/****************************************************
**
**  Desc:   Disables managers that rely on the NWFS archive
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**  Date:   05/09/2008
**          07/24/2008 mem - Changed @ManagerTypeIDList from '1,2,3,4,8' to '2,3,8'
**          07/24/2008 mem - Changed @ManagerTypeIDList from '2,3,8' to '8'
**                         - Note that we do not include 15=CaptureTaskManager because capture tasks can still occur when the archive is unavailable
**                         - However, you should run Stored Procedure enable_disable_archive_step_tools in the DMS_Capture database to disable the archive-dependent step tools
**          02/12/2020 mem - Rename parameter to @infoOnly
**          02/16/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @infoOnly tinyint = 0,
    @message varchar(512)='' output
)
AS
    Set NoCount On

    Declare @myError int

    exec @myerror = enable_disable_all_managers @ManagerTypeIDList='8', @ManagerNameList='', @enable=0,
                                             @infoOnly=@infoOnly, @message = @message output

    Return @myError

GO
GRANT EXECUTE ON [dbo].[disable_archive_dependent_managers] TO [Mgr_Config_Admin] AS [dbo]
GO
