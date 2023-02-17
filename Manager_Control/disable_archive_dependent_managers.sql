/****** Object:  StoredProcedure [dbo].[DisableArchiveDependentManagers] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[DisableArchiveDependentManagers]
/****************************************************
** 
**	Desc:	Disables managers that rely on the NWFS archive
**
**	Return values: 0: success, otherwise, error code
**
**	Auth:	mem
**	Date:	05/09/2008
**			07/24/2008 mem - Changed @ManagerTypeIDList from '1,2,3,4,8' to '2,3,8'
**			07/24/2008 mem - Changed @ManagerTypeIDList from '2,3,8' to '8'
**						   - Note that we do not include 15=CaptureTaskManager because capture tasks can still occur when the archive is unavailable
**						   - However, you should run Stored Procedure EnableDisableArchiveStepTools in the DMS_Capture database to disable the archive-dependent step tools
**          02/12/2020 mem - Rename parameter to @infoOnly
**    
*****************************************************/
(
	@infoOnly tinyint = 0,
	@message varchar(512)='' output
)
As
	Set NoCount On

	Declare @myError int

	exec @myerror = EnableDisableAllManagers @ManagerTypeIDList='8', @ManagerNameList='', @enable=0, 
	                                         @infoOnly=@infoOnly, @message = @message output


	Return @myError


GO
GRANT EXECUTE ON [dbo].[DisableArchiveDependentManagers] TO [Mgr_Config_Admin] AS [dbo]
GO
