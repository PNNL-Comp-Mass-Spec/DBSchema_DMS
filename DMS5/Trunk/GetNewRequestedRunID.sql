/****** Object:  UserDefinedFunction [dbo].[GetNewRequestedRunID] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION dbo.GetNewRequestedRunID
/****************************************************
**
**	Desc: 
**		Returns and ID suitable for making a new requested run
**      for either T_Requested_Run and T_Requested_Run_History
**
**	Return values: Unique ID
**
**		Auth: kja
**		Date: 04/25/2007  Ticket #446
**    
*****************************************************/
()
RETURNS int
AS
BEGIN
	declare @newID int
	set @newID = 0
	--
	SELECT @newID = MAX(M.ID) + 1 FROM
	(
	SELECT ISNULL(MAX(ID), 0) AS ID FROM T_Requested_Run
	UNION
	SELECT ISNULL(MAX(ID), 0) AS ID FROM T_Requested_Run_History
	) M
	
	RETURN @newID
END

GO
