/****** Object:  StoredProcedure [dbo].[GetEnzymeID] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create Procedure GetEnzymeID
/****************************************************
**
**	Desc: Gets enzymeID for given enzyme name
**
**	Return values: 0: failure, otherwise, enzyme ID
**
**	Parameters: 
**
**		Auth: jds
**		Date: 8/25/2004
**    
*****************************************************/
(
		@enzymeName varchar(50) = " "
)
As
	declare @enzymeID int
	set @enzymeID = 0
	SELECT @enzymeID = Enzyme_ID FROM T_Enzymes WHERE (Enzyme_Name = @enzymeName)
	return(@enzymeID)

GO
GRANT EXECUTE ON [dbo].[GetEnzymeID] TO [DMS_SP_User] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[GetEnzymeID] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[GetEnzymeID] TO [PNL\D3M580] AS [dbo]
GO
