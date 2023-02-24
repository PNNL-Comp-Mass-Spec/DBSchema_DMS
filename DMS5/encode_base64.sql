/****** Object:  UserDefinedFunction [dbo].[EncodeBase64] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION dbo.EncodeBase64
/****************************************************
**
**	Desc: 
**		Encodes the given text using base-64 encoding
**
**		From http://stackoverflow.com/questions/5082345/base64-encoding-in-sql-server-2005-t-sql
**
**	Auth:	mem
**	Date:	09/12/2013
**    
*****************************************************/
(
	@TextToEncode varchar(max)
)
RETURNS varchar(max)
AS
BEGIN
	Declare @EncodedText varchar(max)

	SELECT @EncodedText = 
		CAST(N'' AS XML).value(
			'xs:base64Binary(xs:hexBinary(sql:column("bin")))'
			, 'VARCHAR(MAX)'
		)
	FROM (
		SELECT CAST(@TextToEncode AS VARBINARY(MAX)) AS bin
	) AS ConvertQ;
	
	Return @EncodedText
END

GO
GRANT VIEW DEFINITION ON [dbo].[EncodeBase64] TO [DDL_Viewer] AS [dbo]
GO
