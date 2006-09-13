/****** Object:  StoredProcedure [dbo].[GetEUSUserID] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE Procedure dbo.GetEUSUserID
/****************************************************
**
**	Desc: Gets EUS User ID for given EUS User ID
**
**	Return values: 0: failure, otherwise, EUS User ID
**
**	Parameters: 
**
**		Auth: jds
**		Date: 9/1/2006
**    
*****************************************************/
(
	@EUSUserID varchar(32) = " "
)
As
	declare @tempEUSUserID varchar(32)

	set @tempEUSUserID = '0'
	SELECT @tempEUSUserID = PERSON_ID 
	FROM T_EUS_Users WHERE (PERSON_ID = @EUSUserID)

	return(@tempEUSUserID)




GO
