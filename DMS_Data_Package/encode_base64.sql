/****** Object:  UserDefinedFunction [dbo].[encode_base64] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[encode_base64]
/****************************************************
**
**  Desc:
**      Encodes the given text using base-64 encoding
**
**      From http://stackoverflow.com/questions/5082345/base64-encoding-in-sql-server-2005-t-sql
**
**  Auth:   mem
**  Date:   09/12/2013
**          02/15/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @textToEncode varchar(max)
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
GRANT VIEW DEFINITION ON [dbo].[encode_base64] TO [DDL_Viewer] AS [dbo]
GO
