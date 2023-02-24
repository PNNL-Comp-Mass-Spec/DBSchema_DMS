/****** Object:  UserDefinedFunction [dbo].[ValidateWildcardFilter] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[ValidateWildcardFilter]
/****************************************************
**
**  Desc:   Makes sure that @wildcardFilter contains a percent sign
**          Adds percent signs at the beginning and end if it does not have them
**
**  Returns the updated wildcard filter
**
**  Auth:   mem
**  Date:   06/10/2019 mem - Initial version
**
*****************************************************/
(
    @wildcardFilter varchar(4000)          -- Filter text to examine
)
    Returns varchar(4000)
AS
Begin
    Set @wildcardFilter = IsNull(@wildcardFilter, '')

    If Len(IsNull(@wildcardFilter, '')) > 0
    Begin
        -- Add wildcards if @wildcardFilter doesn't contain a percent sign
        If Not @wildcardFilter Like '%[%]%'
        Begin
            Set @wildcardFilter = '%' + @wildcardFilter + '%'
        End
    End

    Return @wildcardFilter
End

GO
