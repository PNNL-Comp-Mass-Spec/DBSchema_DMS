/****** Object:  StoredProcedure [dbo].[disable_sequest_clusters] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[disable_sequest_clusters]
/****************************************************
**
**  Desc:   Disables the Sequest Clusters
**
**  Return values: 0: success, otherwise, error code
**
**  Auth:   mem
**  Date:   07/24/2008
**          10/09/2009 mem - Changed @ManagerTypeIDList to 11
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

    exec @myerror = enable_disable_all_managers @ManagerTypeIDList='11', @ManagerNameList='%SeqCluster%', @enable=0,
                                             @infoOnly=@infoOnly, @message = @message output

    Return @myError

GO
GRANT EXECUTE ON [dbo].[disable_sequest_clusters] TO [Mgr_Config_Admin] AS [dbo]
GO
