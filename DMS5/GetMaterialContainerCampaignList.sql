/****** Object:  UserDefinedFunction [dbo].[GetMaterialContainerCampaignList] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[GetMaterialContainerCampaignList]
/****************************************************
**
**  Desc: 
**      Builds delimited list of campaigns represented
**      by items in the given container
**
**  Return value: delimited list
** 
**  Parameters: 
**
**  Auth:   grk
**  Date:   08/24/2010 grk
**          12/04/2017 mem - Use Coalesce instead of a Case statement
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
GRANT VIEW DEFINITION ON [dbo].[GetMaterialContainerCampaignList] TO [DDL_Viewer] AS [dbo]
GO
