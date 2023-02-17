/****** Object:  StoredProcedure [dbo].[enable_archive_dependent_managers] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[enable_archive_dependent_managers]
/****************************************************
**
**  Desc:   Disables managers that rely on the NWFS archive
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**  Date:   06/09/2011 mem - Initial Version
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

    exec @myerror = enable_disable_all_managers @ManagerTypeIDList='8,15', @ManagerNameList='All', @enable=1,
                                             @infoOnly=@infoOnly, @message = @message output

    Return @myError

GO
GRANT EXECUTE ON [dbo].[enable_archive_dependent_managers] TO [Mgr_Config_Admin] AS [dbo]
GO
