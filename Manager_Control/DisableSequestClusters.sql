/****** Object:  StoredProcedure [dbo].[DisableSequestClusters] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE dbo.DisableSequestClusters
/****************************************************
** 
**	Desc:	Disables the Sequest Clusters
**
**	Return values: 0: success, otherwise, error code
**
**	Auth:	mem
**	Date:	07/24/2008
**			10/09/2009 mem - Changed @ManagerTypeIDList to 11
**    
*****************************************************/
(
	@PreviewUpdates tinyint = 0,
	@message varchar(512)='' output
)
As
	Set NoCount On

	Declare @myError int

	exec @myerror = EnableDisableAllManagers @ManagerTypeIDList='11', @ManagerNameList='%SeqCluster%', @enable=0, 
	                                         @PreviewUpdates=@PreviewUpdates, @message = @message output

	Return @myError



GO
GRANT EXECUTE ON [dbo].[DisableSequestClusters] TO [Mgr_Config_Admin] AS [dbo]
GO
