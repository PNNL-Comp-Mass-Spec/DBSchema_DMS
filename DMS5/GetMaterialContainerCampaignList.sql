/****** Object:  UserDefinedFunction [dbo].[GetMaterialContainerCampaignList] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION GetMaterialContainerCampaignList
/****************************************************
**
**	Desc: 
**  Builds delimited list of campaigns represented
**  by items contained in the given container
**
**	Return value: delimited list
** 
**	Parameters: 
**
**		Auth: grk
**		Date: 08/24/2010
**    
*****************************************************/
(
@containerID INT,
@count int
)
RETURNS varchar(1024)
AS
	BEGIN
		declare @list varchar(8000)
		set @list = ''
		
		IF @count = 0
		RETURN @list
		
		IF @containerID < 1000
		BEGIN
			SET @list = '(temporary)'
		END
		ELSE
		SELECT 
 			@list = @list + CASE 
								WHEN @list = '' THEN Campaign_Num
								ELSE ', ' + Campaign_Num
							END
		FROM
		(
			SELECT DISTINCT Campaign_Num
			FROM 
			(
				SELECT        T_Campaign.Campaign_Num
				FROM            T_Cell_Culture INNER JOIN
										 T_Campaign ON T_Cell_Culture.CC_Campaign_ID = T_Campaign.Campaign_ID
				WHERE        (T_Cell_Culture.CC_Container_ID = @containerID)
				UNION
				SELECT        T_Campaign.Campaign_Num
				FROM            T_Experiments INNER JOIN
										 T_Campaign ON T_Experiments.EX_campaign_ID = T_Campaign.Campaign_ID
				WHERE        (T_Experiments.EX_Container_ID = @containerID)
			) TX
		) TV  ORDER BY Campaign_Num

		RETURN @list
	END
        
GO
GRANT VIEW DEFINITION ON [dbo].[GetMaterialContainerCampaignList] TO [DDL_Viewer] AS [dbo]
GO
