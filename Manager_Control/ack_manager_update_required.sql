/****** Object:  StoredProcedure [dbo].[ack_manager_update_required] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[ack_manager_update_required] 
/****************************************************
**
**	Desc: 
**		Calls AckManagerUpdateRequired to acknowledge that a manager 
**      has seen that ManagerUpdateRequired is True in the manager control DB
**
**	Auth:	mem
**	Date:	04/17/2022 mem - Initial version
**
*****************************************************/
(
	@managerName varchar(128),
	@message varchar(512) = '' output
)
AS

	Declare @returnCode int = 0

    Exec @returnCode = AckManagerUpdateRequired @managerName, @message = @message output

    Return @returnCode


GO
GRANT EXECUTE ON [dbo].[ack_manager_update_required] TO [DMS_Analysis_Job_Runner] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[ack_manager_update_required] TO [Mgr_Config_Admin] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[ack_manager_update_required] TO [svc-dms] AS [dbo]
GO
