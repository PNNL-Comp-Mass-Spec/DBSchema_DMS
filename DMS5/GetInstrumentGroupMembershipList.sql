/****** Object:  UserDefinedFunction [dbo].[GetInstrumentGroupMembershipList] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[GetInstrumentGroupMembershipList]
/****************************************************
**
**	Desc: 
**  Builds delimited list of associated instruments
**  for given instrument group
**
**	Return value: delimited list
**
**	Parameters: 
**
**	Auth:	grk
**	Date:	08/30/2010 grk - Initial version
**    
*****************************************************/
(
	@InstrumentGroup VARCHAR(64)
)
RETURNS varchar(4000)
AS
	BEGIN
		declare @list varchar(4000)
		
		Set @list = ''
		
		SELECT @list = @list + CASE WHEN @list = '' THEN '' ELSE ', ' END + IN_name     
		FROM            T_Instrument_Name
		WHERE        (IN_Group = @InstrumentGroup)	
		
		RETURN @list
	END

GO
GRANT EXECUTE ON [dbo].[GetInstrumentGroupMembershipList] TO [DMS2_SP_User] AS [dbo]
GO
