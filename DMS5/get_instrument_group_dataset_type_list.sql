/****** Object:  UserDefinedFunction [dbo].[GetInstrumentGroupDatasetTypeList] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[GetInstrumentGroupDatasetTypeList]
/****************************************************
**
**  Desc:
**      Builds delimited list of allowed dataset types
**      for given instrument group
**
**  Return value: delimited list
**
**  Auth:   grk
**  Date:   08/28/2010 grk - Initial version
**          02/04/2021 mem - Add argument @delimiter
**
*****************************************************/
(
    @instrumentGroup varchar(64),
    @delimiter varchar(12) = ', '
)
RETURNS varchar(4000)
AS
    BEGIN
        Declare @list varchar(4000)

        Set @list = ''

        SELECT @list = @list +
                       CASE WHEN @list = '' THEN '' ELSE @delimiter END +
                       Dataset_Type
        FROM T_Instrument_Group_Allowed_DS_Type
        WHERE IN_Group = @InstrumentGroup
        ORDER BY Dataset_Type

        RETURN @list
    END

GO
GRANT VIEW DEFINITION ON [dbo].[GetInstrumentGroupDatasetTypeList] TO [DDL_Viewer] AS [dbo]
GO
