/****** Object:  StoredProcedure [dbo].[GetCellCultureID] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE GetCellCultureID
/****************************************************
**
**	Desc: Gets CC_ID for given cell culture name
**
**	Return values: 0: failure, otherwise, campaign ID
**
**	Auth:	grk
**	Date:	03/26/2003
**			08/03/2017 mem - Add Set NoCount On
**    
*****************************************************/
(
	@cellCultureName varchar(128) = " "
)
As
	Set NoCount On
	
	Declare @ccID int = 0

	SELECT @ccID = CC_ID
	FROM T_Cell_Culture
	WHERE CC_Name = @cellCultureName

	return @ccID
GO
GRANT VIEW DEFINITION ON [dbo].[GetCellCultureID] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[GetCellCultureID] TO [Limited_Table_Write] AS [dbo]
GO
