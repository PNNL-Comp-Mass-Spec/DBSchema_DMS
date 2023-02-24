/****** Object:  StoredProcedure [dbo].[GetTissueID] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE dbo.GetTissueID
/****************************************************
**
**	Desc: 
**		Gets TissueID for given Tissue Name or Tissue Id
**
**	Return values:
**		0 if success, error code if a problem 
**		(code 100 means "Entry not found)
**
**	Auth:	mem
**	Date:	09/01/2017 mem - Initial version
**			10/09/2017 mem - Auto-change @tissue to '' if 'none', 'na', or 'n/a'
**    
*****************************************************/
(
	@tissueNameOrID varchar(128),				-- Tissue Name or Tissue Identifier to find
	@tissueIdentifier varchar(24) output,		-- Output: Tissue identifier, e.g. BTO:0000131
	@tissueName varchar(128) output				-- Output: Human readable tissue name, e.g. plasma
)
As
	Set NoCount On

	Declare @myError int = 0
	Declare @myRowCount int = 0

	Set @tissueNameOrID = LTrim(RTrim(IsNull(@tissueNameOrID, '')))

	Set @tissueIdentifier = null
	Set @tissueName = null
	
	If @tissueNameOrID IN ('none', 'na', 'n/a')
		Set @tissueNameOrID = ''

	If Len(@tissueNameOrID) > 0
	Begin
		If @tissueNameOrID Like 'BTO:%'
		Begin
			SELECT @tissueIdentifier = Identifier,
			       @tissueName = Tissue
			FROM S_V_BTO_ID_to_Name
			WHERE Identifier = @tissueNameOrID
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			--	
			If @myRowCount = 0 And @myError = 0
			Begin
				Set @myError = 100
			End				
		End
		Else
		Begin
			SELECT @tissueIdentifier = Identifier,
			       @tissueName = Tissue
			FROM S_V_BTO_ID_to_Name
			WHERE Tissue = @tissueNameOrID
			--
			SELECT @myError = @@error, @myRowCount = @@rowcount
			--	
			If @myRowCount = 0 And @myError = 0
			Begin
				Set @myError = 100
			End
		End
		
	End
	
	return @myError


GO
