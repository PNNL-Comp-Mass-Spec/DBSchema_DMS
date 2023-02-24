/****** Object:  UserDefinedFunction [dbo].[get_aj_processor_membership_in_groups_list] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[get_aj_processor_membership_in_groups_list]
/****************************************************
**
**  Desc:
**  Builds delimited list of processor group IDs
**  for given analysis job processor ID
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
    @processorID int,
    @enableDisableFilter tinyint    -- 0 means disabled only, 1 means enabled only, anything else means all
)
RETURNS varchar(4000)
AS
    BEGIN
        declare @CombinedList varchar(4000)
        declare @EnabledGroups varchar(4000)
        declare @DisabledGroups varchar(4000)

        set @CombinedList = ''

        set @EnabledGroups = ''
        If @EnableDisableFilter <> 0
        Begin
            SELECT @EnabledGroups = @EnabledGroups + CAST(ID as Varchar(12)) + ': ' + AJPG.Group_Name + ', '
            FROM T_Analysis_Job_Processor_Group_Membership AJPGM INNER JOIN
                 T_Analysis_Job_Processor_Group AJPG ON AJPGM.Group_ID = AJPG.ID
            WHERE AJPGM.Processor_ID = @processorID AND
                  Membership_Enabled = 'Y'
            ORDER BY AJPG.Group_Name
        End

        set @DisabledGroups = ''
        If @EnableDisableFilter <> 1
        Begin
            SELECT @DisabledGroups = @DisabledGroups + CAST(ID as Varchar(12)) + ': ' + AJPG.Group_Name + ', '
            FROM T_Analysis_Job_Processor_Group_Membership AJPGM INNER JOIN
                 T_Analysis_Job_Processor_Group AJPG ON AJPGM.Group_ID = AJPG.ID
            WHERE AJPGM.Processor_ID = @processorID AND
                  Membership_Enabled <> 'Y'
            ORDER BY AJPG.Group_Name
        End

        If Len(@EnabledGroups) > 2
        Begin
            If @EnableDisableFilter <> 0 And @EnableDisableFilter <> 1
                Set @CombinedList = 'Enabled: '
            Set @CombinedList = @CombinedList + Left(@EnabledGroups, Len(@EnabledGroups)-1)
        End

        If Len(@DisabledGroups) > 2
        Begin
            If Len(@CombinedList) > 0
                Set @CombinedList = @CombinedList + '; '

            If @EnableDisableFilter <> 0 And @EnableDisableFilter <> 1
                Set @CombinedList = 'Disabled: '

            Set @CombinedList = @CombinedList + Left(@DisabledGroups, Len(@DisabledGroups)-1)
        End

        RETURN @CombinedList
    END

GO
GRANT EXECUTE ON [dbo].[get_aj_processor_membership_in_groups_list] TO [D3L243] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[get_aj_processor_membership_in_groups_list] TO [DDL_Viewer] AS [dbo]
GO
