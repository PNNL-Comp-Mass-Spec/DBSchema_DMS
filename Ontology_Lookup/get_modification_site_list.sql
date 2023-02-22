/****** Object:  UserDefinedFunction [dbo].[get_modification_site_list] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[get_modification_site_list]
/****************************************************
**
**  Desc:
**  Builds delimited list of modification sites for given Unimod ID
**
**  Return value: delimited list
**
**  Parameters:
**
**  Auth:   mem
**  Date:   05/15/2013 mem - Initial version
**          03/29/2022 mem - Add support for returning all modification sites when @Hidden is greater than 1
**          02/21/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @unimodID int,
    @hidden tinyint
)
RETURNS
@TableOfResults TABLE
(
    -- Add the column definitions for the TABLE variable here
    Unimod_ID int,
    Sites varchar(255)
)
AS
BEGIN
    Declare @list varchar(4000) = ''

    SELECT @list = @list + CASE WHEN @list = '' THEN '' ELSE ', ' END + Sites
    FROM (SELECT CASE WHEN Position IN ('Anywhere', 'Any N-Term', 'Any C-term')
              THEN Site WHEN Site LIKE '_-term' THEN Position ELSE Site + ' @ ' + Position END AS Sites
          FROM T_Unimod_Specificity
          WHERE Unimod_ID = @UnimodID And (Hidden = @Hidden Or @Hidden > 1)
         ) SourceQ
    ORDER BY Sites

    INSERT INTO @TableOfResults(Unimod_ID, Sites)
        Values (@UnimodID, @list)

    RETURN
END

GO
GRANT VIEW DEFINITION ON [dbo].[get_modification_site_list] TO [DDL_Viewer] AS [dbo]
GO
