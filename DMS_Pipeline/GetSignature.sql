/****** Object:  StoredProcedure [dbo].[GetSignature] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE dbo.GetSignature
/****************************************************
**
**	Desc:
**    Get signature for given input string
**
**    Input string is hashed to pattern, and stored in table
**    Signature is integer reference to pattern
**	
**	Return values: signature: otherwise, 0
**
**	Auth:	grk
**	Date:	08/22/2008 grk - Initial release (http://prismtrac.pnl.gov/trac/ticket/666)
**			03/22/2011 mem - Now populating String, Entered, and Last_Used in T_Signatures
**    
*****************************************************/
(
	@s varchar(max)
)
AS
	declare @pattern varchar(32)
	declare @reference int

	set @reference = 0

	---------------------------------------------------
	-- convert string to hash
	---------------------------------------------------
	
	set @pattern = dbo.bin2hex(HashBytes('SHA1', @s))   
	
	---------------------------------------------------
	-- is it already in table?
	---------------------------------------------------
	--
	SELECT @reference = Reference
	FROM T_Signatures
	WHERE Pattern = @pattern
	
	If @reference = 0
	Begin

		---------------------------------------------------
		-- Pattern not found; add it
		---------------------------------------------------

		INSERT INTO T_Signatures( Pattern,
		                          String,
		                          Entered,
		                          Last_Used )
		VALUES(@pattern, @s, GetDate(), GetDate())
	  
		---------------------------------------------------
		-- get Reference for newly-inserted Pattern
		---------------------------------------------------
		--
  		SELECT @reference = Reference
  		FROM T_Signatures
  		WHERE Pattern = @pattern

	End
	Else
	Begin
		---------------------------------------------------
		-- Update Last_Used and possibly update String
		---------------------------------------------------
		--
		IF Exists (SELECT * FROM T_Signatures WHERE Reference = @reference AND string IS NULL)
			UPDATE T_Signatures
			SET Last_Used = GetDate(),
			    String = @s
			WHERE Reference = @reference
		Else
			UPDATE T_Signatures
			SET Last_Used = GetDate()
			WHERE Reference = @reference
	End
	
   
	---------------------------------------------------
	-- Exit
	---------------------------------------------------
	--
Done:
	RETURN @reference



GO
GRANT VIEW DEFINITION ON [dbo].[GetSignature] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[GetSignature] TO [Limited_Table_Write] AS [dbo]
GO
