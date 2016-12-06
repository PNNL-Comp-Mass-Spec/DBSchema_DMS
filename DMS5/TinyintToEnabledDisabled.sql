/****** Object:  UserDefinedFunction [dbo].[TinyintToEnabledDisabled] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION dbo.TinyintToEnabledDisabled
/****************************************************
**
**	Desc: 
**		Returns the text 'Disabled' if @value=0, otherwise returns 'Enabled'
**
**	Return values: Path to the folder containing the Fasta file
**
**	Auth:	kja
**	Date:	01/23/2007
**			09/06/2007 mem - Updated to reflect Protein_Sequences DB move to server ProteinSeqs (Ticket #531)
**    
*****************************************************/
(
	@value tinyint
)
RETURNS varchar(16)
AS
Begin
	Declare @text varchar(16)
	If IsNull(@value, 0) = 0
		Set @text = 'Disabled'
	Else
		Set @text = 'Enabled'
	
	Return @text
End

GO
GRANT VIEW DEFINITION ON [dbo].[TinyintToEnabledDisabled] TO [DDL_Viewer] AS [dbo]
GO
