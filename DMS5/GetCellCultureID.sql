/****** Object:  StoredProcedure [dbo].[GetCellCultureID] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

Create Procedure GetCellCultureID
/****************************************************
**
**	Desc: Gets CC_ID for given cell culture name
**
**	Return values: 0: failure, otherwise, campaign ID
**
**	Parameters: 
**
**		Auth: grk
**		Date: 3/26/2003
**    
*****************************************************/
(
		@cellCultureName varchar(128) = " "
)
As
	declare @ccID int
	set @ccID = 0
	SELECT @ccID = CC_ID FROM T_Cell_Culture WHERE (CC_Name = @cellCultureName)
	return(@ccID)
GO
GRANT VIEW DEFINITION ON [dbo].[GetCellCultureID] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[GetCellCultureID] TO [Limited_Table_Write] AS [dbo]
GO
