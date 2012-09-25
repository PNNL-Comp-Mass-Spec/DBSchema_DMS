/****** Object:  StoredProcedure [dbo].[EnableArchiveDependentManagers] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE dbo.EnableArchiveDependentManagers
/****************************************************
** 
**	Desc:	Disables managers that rely on the NWFS archive
**
**	Return values: 0: success, otherwise, error code
**
**	Auth:	mem
**	Date:	06/09/2011 mem - Initial Version
**    
*****************************************************/
(
	@PreviewUpdates tinyint = 0,
	@message varchar(512)='' output
)
As
	Set NoCount On

	Declare @myError int

	exec @myerror = EnableDisableAllManagers @ManagerTypeIDList='8,15', @ManagerNameList='All', @enable=1, 
	                                         @PreviewUpdates=@PreviewUpdates, @message = @message output


	Return @myError


GO
GRANT EXECUTE ON [dbo].[EnableArchiveDependentManagers] TO [Mgr_Config_Admin] AS [dbo]
GO
