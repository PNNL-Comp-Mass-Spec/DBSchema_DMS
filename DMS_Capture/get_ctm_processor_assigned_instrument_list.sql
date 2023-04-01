/****** Object:  UserDefinedFunction [dbo].[get_ctm_processor_assigned_instrument_list] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[get_ctm_processor_assigned_instrument_list]
/****************************************************
**
**  Desc:
**      Builds delimited list of assigned instruments for the given processor
**
**  Return value: delimited list
**
**  Parameters:
**
**  Auth:   grk
**  Date:   01/21/2010
**          02/17/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**          04/01/2023 mem - Rename procedures and functions
**
*****************************************************/
(
    @processorName varchar(256)
)
RETURNS varchar(4000)
AS
    BEGIN
        declare @list varchar(4000)
        set @list = ''

        SELECT
            @list = CASE WHEN @list = '' THEN Instrument_Name ELSE @list + ', ' + Instrument_Name END
        FROM
            T_Processor_Instrument
        WHERE
            Processor_Name = @ProcessorName
            AND (Enabled > 0)
        ORDER BY Instrument_Name

        RETURN @list
    END

GO
GRANT VIEW DEFINITION ON [dbo].[get_ctm_processor_assigned_instrument_list] TO [DDL_Viewer] AS [dbo]
GO
