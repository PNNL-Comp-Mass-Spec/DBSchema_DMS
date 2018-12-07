/****** Object:  StoredProcedure [dbo].[UpdateExperimentGroupMemberCount] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[UpdateExperimentGroupMemberCount]
/****************************************************
**
**	Desc: 
**	    Updates the MemberCount value for either the 
**      specific experiment group or for all experiment groups
**
**	Return values: 0: success, otherwise, error code
**
**	Auth:	mem
**	Date:	12/06/2018 mem - Initial version
**    
*****************************************************/
(
	@groupID int = 0,           -- 0 to Update all groups
	@message varchar(512) = '' output
)
As
	Declare @myError int = 0
	Declare @myRowCount int = 0

    ---------------------------------------------------
	-- Validate inputs
	---------------------------------------------------

    Set @groupID = IsNull(@groupID, 0)
	Set @message = ''

    If @groupID <= 0
    Begin
    
        UPDATE T_Experiment_Groups
        SET MemberCount = LookupQ.MemberCount
        FROM T_Experiment_Groups EG
             INNER JOIN ( SELECT Group_ID, Count(*) AS MemberCount
                          FROM T_Experiment_Group_Members
                          GROUP BY Group_ID) LookupQ
               ON EG.Group_ID = LookupQ.Group_ID
        WHERE EG.MemberCount <> LookupQ.MemberCount
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        If @myRowCount > 0
        Begin
            Set @message = 'Updated member counts for ' + Cast(@myRowCount As Varchar(12)) + ' groups in T_Experiment_Groups'
            Print @message
        End
        Else
        Begin
            Set @message = 'Member counts were already up-to-date for all groups in T_Experiment_Groups'
        End
    End
    Else
    Begin
    
        Declare @memberCount Int = 0
            
        SELECT @memberCount = Count(*)
        FROM T_Experiment_Group_Members
        WHERE Group_ID = @groupID 
        GROUP BY Group_ID

        UPDATE T_Experiment_Groups
        SET MemberCount = IsNull(@memberCount, 0)
        WHERE Group_ID = @groupID 
        --
        SELECT @myError = @@error, @myRowCount = @@rowcount

        Set @message = 'Experiment group ' + Cast(@groupID As Varchar(12)) + ' now has ' + Cast(@myRowCount As Varchar(12)) + ' members'
    End
    	
	return 0

GO
