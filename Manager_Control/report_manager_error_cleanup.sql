/****** Object:  StoredProcedure [dbo].[report_manager_error_cleanup] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[report_manager_error_cleanup] 
/****************************************************
**
**	Desc: 
**		Calls ReportManagerErrorCleanup to report that the manager tried to auto-cleanup
**		when there is a flag file or non-empty working directory
**
**	Auth:	mem
**	Date:	04/17/2022 mem - Initial version
**
*****************************************************/
(
	@ManagerName varchar(128),
	@State int = 0,					-- 1 = Cleanup Attempt start, 2 = Cleanup Successful, 3 = Cleanup Failed
	@FailureMsg varchar(512) = '',
	@message varchar(512) = '' output
)
AS
	
    Declare @returnCode int

    Exec @returnCode = ReportManagerErrorCleanup @ManagerName, @State, @FailureMsg, @message = @message output

    Return @returnCode
	

GO
GRANT EXECUTE ON [dbo].[report_manager_error_cleanup] TO [DMS_Analysis_Job_Runner] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[report_manager_error_cleanup] TO [Mgr_Config_Admin] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[report_manager_error_cleanup] TO [svc-dms] AS [dbo]
GO
