/****** Object:  UserDefinedFunction [dbo].[GetRequestedRunNameCode] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[GetRequestedRunNameCode]
/****************************************************
**
**	Desc: 
**		Generates the Name Code string for a given requested run
**		This string is used when grouping requested runs for run planning purposes
**
**		The request name code will be based on the request name, date, and requester PRN if @BatchName is empty
**		Otherwise, if @BatchName is valid, then it is based on the batch name, date, and requester PRN
**
**		Examples:
**			Mix_20100805_R_D3X414
**			She_20100805_B_D3X414
**
**	Return value: string
**
**	Parameters: 
**
**	Auth:	mem
**	Date:	08/05/2010
**			08/10/2010 mem - Added @DatasetTypeID and @SeparationType
**						   - Increased size of return string to varchar(64)
**    
*****************************************************/
(
	@RequestName varchar(128),
	@RequestCreated datetime,
	@RequesterPRN varchar(64),
	@BatchID int,
	@BatchName varchar(128),
	@BatchCreated datetime,
	@BatchRequesterPRN varchar(64),
	@DatasetTypeID int,
	@SeparationType varchar(32)
)
RETURNS varchar(64)
AS
BEGIN
    Return CASE WHEN @BatchID = 0 
                THEN
					SUBSTRING(@RequestName, 1, 3) + '_' + 
					CONVERT(varchar(10), @RequestCreated, 112) + '_' + 
					'R_' + 
		            @RequesterPRN + '_' +
		            CONVERT(varchar(4), ISNULL(@DatasetTypeID, 0)) + '_' +
		            IsNull(@SeparationType, '')
		        ELSE
		            SUBSTRING(@BatchName, 1, 3) + '_' + 
		            CONVERT(varchar(10), @BatchCreated, 112) + '_' + 
		            'B_' + 
		            @BatchRequesterPRN + '_' +
		            CONVERT(varchar(4), ISNULL(@DatasetTypeID, 0)) + '_' +
		            IsNull(@SeparationType, '')
		            
		   END
END


GO
