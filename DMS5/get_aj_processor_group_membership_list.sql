/****** Object:  UserDefinedFunction [dbo].[get_aj_processor_group_membership_list] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[get_aj_processor_group_membership_list]
/****************************************************
**
**  Desc:
**  Builds delimited list of analysis job processors
**  for given analysis job processor group ID
**
**  Return value: delimited list
**
**  Parameters:
**
**  Auth:   grk
**  Date:   02/12/2007
**          02/20/2007 grk - Fixed reference to group ID
**          02/22/2007 mem - Now grouping processors by Membership_Enabled values
**          02/23/2007 mem - Added parameter @EnableDisableFilter
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @groupID int,
    @enableDisableFilter tinyint    -- 0 means disabled only, 1 means enabled only, anything else means all
)
RETURNS varchar(4000)
AS
    BEGIN
        declare @CombinedList varchar(4000)
        declare @EnabledProcs varchar(4000)
        declare @DisabledProcs varchar(4000)

        set @EnableDisableFilter = IsNull(@EnableDisableFilter, 2)
        set @CombinedList = ''

        set @EnabledProcs = ''
        If @EnableDisableFilter <> 0
        Begin
            SELECT @EnabledProcs = @EnabledProcs + AJP.Processor_Name + ', '
            FROM T_Analysis_Job_Processor_Group_Membership AJPGM INNER JOIN
                T_Analysis_Job_Processors AJP ON AJPGM.Processor_ID = AJP.ID
            WHERE AJPGM.Group_ID = @groupID AND
                Membership_Enabled = 'Y'
            ORDER BY AJP.Processor_Name
        End

        set @DisabledProcs = ''
        If @EnableDisableFilter <> 1
        Begin
            SELECT @DisabledProcs = @DisabledProcs + AJP.Processor_Name + ', '
            FROM T_Analysis_Job_Processor_Group_Membership AJPGM INNER JOIN
                T_Analysis_Job_Processors AJP ON AJPGM.Processor_ID = AJP.ID
            WHERE AJPGM.Group_ID = @groupID AND
                Membership_Enabled <> 'Y'
            ORDER BY AJP.Processor_Name
        End

        If Len(@EnabledProcs) > 2
        Begin
            If @EnableDisableFilter <> 0 And @EnableDisableFilter <> 1
                Set @CombinedList = 'Enabled: '
            Set @CombinedList =  @CombinedList + Left(@EnabledProcs, Len(@EnabledProcs)-1)
        End

        If Len(@DisabledProcs) > 2
        Begin
            If Len(@CombinedList) > 0
                Set @CombinedList = @CombinedList + '; '

            If @EnableDisableFilter <> 0 And @EnableDisableFilter <> 1
                Set @CombinedList = 'Disabled: '

            Set @CombinedList = @CombinedList + Left(@DisabledProcs, Len(@DisabledProcs)-1)
        End

        RETURN @CombinedList
    END

GO
GRANT VIEW DEFINITION ON [dbo].[get_aj_processor_group_membership_list] TO [DDL_Viewer] AS [dbo]
GO
