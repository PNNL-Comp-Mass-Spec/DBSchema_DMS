/****** Object:  StoredProcedure [dbo].[disable_analysis_managers] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[disable_analysis_managers]
/****************************************************
**
**  Desc:   Disables all analysis managers
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**  Date:   05/09/2008
**          10/09/2009 mem - Changed @ManagerTypeIDList to 11
**          06/09/2011 mem - Now calling enable_disable_all_managers
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

    exec @myerror = enable_disable_all_managers @managerTypeIDList='11', @managerNameList='', @enable=0,
                                             @infoOnly=@infoOnly, @message = @message output

    Return @myError

GO
GRANT EXECUTE ON [dbo].[disable_analysis_managers] TO [Mgr_Config_Admin] AS [dbo]
GO
