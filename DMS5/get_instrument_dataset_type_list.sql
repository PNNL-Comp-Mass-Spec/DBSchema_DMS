/****** Object:  UserDefinedFunction [dbo].[get_instrument_dataset_type_list] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[get_instrument_dataset_type_list]
/****************************************************
**
**  Desc:
**  Builds delimited list of allowed dataset types
**  for given instrument ID
**
**  Return value: delimited list
**
**  Parameters:
**
**  Auth:   mem
**  Date:   09/17/2009 mem - Initial version (Ticket #748)
**          08/28/2010 mem - Updated to use get_instrument_group_dataset_type_list
**          02/04/2021 mem - Provide a delimiter when calling get_instrument_group_dataset_type_list
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @instrumentID int
)
RETURNS varchar(4000)
AS
    BEGIN
        declare @list varchar(4000) = ''
        Declare @InstrumentGroup varchar(64) = ''

        -- Lookup the instrument group for this instrument

        SELECT @InstrumentGroup = IN_Group
        FROM T_Instrument_Name
        WHERE Instrument_ID = @InstrumentID

        IF @InstrumentGroup <> ''
            SELECT @list = dbo.get_instrument_group_dataset_type_list(@InstrumentGroup, ', ')

        RETURN @list
    END

GO
GRANT VIEW DEFINITION ON [dbo].[get_instrument_dataset_type_list] TO [DDL_Viewer] AS [dbo]
GO
