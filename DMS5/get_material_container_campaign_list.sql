/****** Object:  UserDefinedFunction [dbo].[get_material_container_campaign_list] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[get_material_container_campaign_list]
/****************************************************
**
**  Desc:
**      Builds delimited list of campaigns represented by items in the given container
**
**      This function was previously used by views V_Material_Containers_List_Report and V_Material_Containers_Detail_Report
**      but is no longer used, since column Campaign_ID was added to table T_Material_Containers in November 2023
**
**  Return value: comma-separated list
**
**  Arguments:
**    @containerID  Container ID
**    @count        Number of items in the container; if 0, return an empty string without querying any tables, otherwise, if null or non-zero query the database
**
**  Auth:   grk
**  Date:   08/24/2010 grk
**          12/04/2017 mem - Use Coalesce instead of a Case statement
**          02/23/2023 bcg - Rename procedure and parameters to a case-insensitive match to postgres
**
*****************************************************/
(
    @containerID INT,
    @count int
)
RETURNS varchar(1024)
AS
BEGIN
    declare @list varchar(8000) = null

    If @count = 0
    RETURN ''

    If @containerID < 1000
    BEGIN
       SET @list = '(temporary)'
    END
    ELSE
        SELECT @list = Coalesce(@list + ', ' + Campaign_Name, Campaign_Name)
        FROM ( SELECT DISTINCT Campaign_Name
               FROM (SELECT T_Campaign.Campaign_Num AS Campaign_Name
                     FROM T_Cell_Culture
                          INNER JOIN T_Campaign
                            ON T_Cell_Culture.CC_Campaign_ID = T_Campaign.Campaign_ID
                     WHERE T_Cell_Culture.CC_Container_ID = @containerID
                     UNION
                     SELECT T_Campaign.Campaign_Num AS Campaign_Name
                     FROM T_Experiments
                          INNER JOIN T_Campaign
                            ON T_Experiments.EX_campaign_ID = T_Campaign.Campaign_ID
                     WHERE T_Experiments.EX_Container_ID = @containerID
                     ) Campaigns
               ) DistinctCampaigns
        ORDER BY Campaign_Name

    RETURN IsNull(@list, '')
END

GO
GRANT VIEW DEFINITION ON [dbo].[get_material_container_campaign_list] TO [DDL_Viewer] AS [dbo]
GO
