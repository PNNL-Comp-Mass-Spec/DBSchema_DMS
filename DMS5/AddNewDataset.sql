/****** Object:  StoredProcedure [dbo].[AddNewDataset] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE AddNewDataset
/****************************************************
**	Desc: 
**  Adds new dataset entry to DMS database.
**  This is for use by sample automation software
**  associated with the mass spec instrument to
**  create new datasets automatically following
**  an instrument run.
**
**	Return values: 0: success, otherwise, error code
** 
**	Parameters:
**
**		Auth: grk
**		Date: 6/10/2005
**      2/23/2006   -- grk EUS tracking columns in request and history tables.
**    
*****************************************************/
	@datasetNum varchar(64),
	@experimentNum varchar(64),
	@operPRN varchar(64),
	@instrumentName varchar(64),
	@msType varchar(20),
	@LCColumnNum varchar(64),
	@LCCartName varchar(128),
	@wellplateNum varchar(64) = 'na',
	@wellNum varchar(64) = 'na',
	@secSep varchar(64) = 'na',
	@internalStandards varchar(64) = 'none',
	@comment varchar(512) = 'na',
	@rating varchar(32) = 'Unknown',
	@requestID int = 0,
	@eusProposalID varchar(10) = 'na',
	@eusUsageType varchar(50),
	@eusUsersList varchar(1024) = '',
	@message varchar(512) output
AS
	set nocount on

	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	
	set @message = ''

	RETURN 0


GO
