/****** Object:  StoredProcedure [dbo].[DisableAnalysisManagers] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[DisableAnalysisManagers]
/****************************************************
** 
**	Desc:	Disables all analysis managers
**
**	Return values: 0: success, otherwise, error code
**
**	Auth:	mem
**	Date:	05/09/2008
**			10/09/2009 mem - Changed @ManagerTypeIDList to 11
**			06/09/2011 mem - Now calling EnableDisableAllManagers
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

	exec @myerror = EnableDisableAllManagers @ManagerTypeIDList='11', @ManagerNameList='', @enable=0, 
	                                         @infoOnly=@infoOnly, @message = @message output

	Return @myError



GO
GRANT EXECUTE ON [dbo].[DisableAnalysisManagers] TO [Mgr_Config_Admin] AS [dbo]
GO
