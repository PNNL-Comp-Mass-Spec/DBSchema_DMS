/****** Object:  StoredProcedure [dbo].[UpdateUserPermissionsViewDefinitions] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[UpdateUserPermissionsViewDefinitions]
/****************************************************
**
**	Temporary wrapper for renamed procedure
**    
*****************************************************/
(
	@roleOrUserList varchar(255) = 'DDL_Viewer',
	@revokeList varchar(255) = 'PNL\D3M578, PNL\D3M580',
	@updateTables tinyint = 1,
	@updateSPs tinyint = 1,
	@updateViews tinyint = 1,
	@updateOther tinyint = 1,
	@previewSql tinyint = 0,
	@message varchar(512)='' output
)
AS
	Declare @myError int
    EXEC @myError = update_user_permissions_view_definitions @roleOrUserList, @revokeList, @updateTables, @updateSPs, @updateViews, @updateOther, @previewSql, @message output
	Return @myError

GO
GRANT VIEW DEFINITION ON [dbo].[UpdateUserPermissionsViewDefinitions] TO [DDL_Viewer] AS [dbo]
GO
