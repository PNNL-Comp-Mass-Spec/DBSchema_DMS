/****** Object:  StoredProcedure [dbo].[CreateResultsFolderName] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create PROCEDURE CreateResultsFolderName
/****************************************************
**
**	Desc: 
**  Calculate results folder name for given job
**    Make entries in temporary table:
**      #Job
**	
**	Return values: 0: success, otherwise, error code
**
**
**	Auth:	grk
**	01/31/2009 grk -- initial release  (http://prismtrac.pnl.gov/trac/ticket/720)
**    
*****************************************************/
(
	@job int,
	@tag varchar(8),
	@resultsFolderName varchar(128) output,
	@message varchar(512) output
)
As
	set nocount on
	
	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	
	set @message = ''

	-- Create job results folder name
	---------------------------------------------------

	-- The auto-generated name has these components, all combined into one string:
	--  a) the 3-letter Results Tag,
	--  b) the current date, format yyyyMMdd, for example 20081205 for 2008-12-05
	--  c) the current time, format hhmm, for example 1017 for 10:17 am
	--  d) the text _Auto
	--  e) the Job number
	--
	set @resultsFolderName = @tag + replace(convert(varchar, getdate(),111),'/','') + substring(replace(convert(varchar, getdate(),108),':',''), 1, 4)
	--
	set @resultsFolderName = @resultsFolderName + '_Auto' + convert(varchar(12), @job)
	
	--
	UPDATE #Jobs
	SET Results_Folder_Name = @resultsFolderName
	WHERE Job = @job		
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	--
	if @myError <> 0
	begin
		set @message = 'Error creating job results folder name'
	end

GO
GRANT VIEW DEFINITION ON [dbo].[CreateResultsFolderName] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[CreateResultsFolderName] TO [Limited_Table_Write] AS [dbo]
GO
