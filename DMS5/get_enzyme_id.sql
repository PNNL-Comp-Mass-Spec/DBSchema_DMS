/****** Object:  StoredProcedure [dbo].[GetEnzymeID] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE GetEnzymeID
/****************************************************
**
**	Desc: Gets enzymeID for given enzyme name
**
**	Return values: 0: failure, otherwise, enzyme ID
**
**	Parameters: 
**
**	Auth:	jds
**	Date:	08/25/2004
**			08/03/2017 mem - Add Set NoCount On
**    
*****************************************************/
(
	@enzymeName varchar(50) = " "
)
As
	Set NoCount On
	
	Declare @enzymeID int = 0
	
	SELECT @enzymeID = Enzyme_ID
	FROM T_Enzymes
	WHERE Enzyme_Name = @enzymeName

	return @enzymeID

GO
GRANT VIEW DEFINITION ON [dbo].[GetEnzymeID] TO [DDL_Viewer] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[GetEnzymeID] TO [DMS_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[GetEnzymeID] TO [Limited_Table_Write] AS [dbo]
GO
