/****** Object:  StoredProcedure [dbo].[ImportProcessors] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[ImportProcessors]
/****************************************************
**
**	Desc:
**    get list of processors
**	
**	Return values: 0: success, otherwise, error code
**
**
**	Auth:	grk
**			06/03/2008 grk - Initial release (http://prismtrac.pnl.gov/trac/ticket/666)
**			09/03/2009 mem - Now skipping disabled processors when looking for new processors to import
**			11/11/2013 mem - Now setting ProcTool_Mgr_ID to 1 for newly added processors
**          10/14/2022 mem - Remove invalid update query that aimed to disable local processors that were not in DMS, but didn't actually work
**    
*****************************************************/
(
	@bypassDMS tinyint = 0,
	@message varchar(512) output
)
As
	set nocount on
	
	Declare @myError int = 0
	Declare @myRowCount int = 0
	
	set @message = ''
	
	if @bypassDMS <> 0
		goto Done

	---------------------------------------------------
	-- add processors from DMS that aren't already in local table
	---------------------------------------------------
	--
	INSERT INTO T_Local_Processors
		(ID, Processor_Name, State, Groups, GP_Groups, Machine, ProcTool_Mgr_ID)
	SELECT
		ID, Processor_Name, State, Groups, GP_Groups, Machine, 1
	FROM
		V_DMS_PipelineProcessors VPP
	WHERE VPP.State = 'E' AND
	      Processor_Name NOT IN (SELECT Processor_Name FROM T_Local_Processors)
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
     --
	if @myError <> 0
	begin
		set @message = 'Error copying new job-processor associations from DMS'
		goto Done
	end

	---------------------------------------------------
	-- Update local processors
	---------------------------------------------------
	--
	UPDATE
		T_Local_Processors
	SET
		State = VPP.State, 
		Groups = VPP.Groups, 
		GP_Groups = VPP.GP_Groups, 
		Machine = VPP.Machine
	FROM
		T_Local_Processors INNER JOIN
		V_DMS_PipelineProcessors AS VPP ON T_Local_Processors.Processor_Name = VPP.Processor_Name
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
	 --
	if @myError <> 0
	begin
		set @message = 'Error updating existing processors'
		goto Done
	end

	---------------------------------------------------
	-- Deprecated: disable local copies that are not in DMS
	---------------------------------------------------
	--
	-- Update T_Local_Processors
	-- Set State = 'X'
	-- From T_Local_Processors INNER JOIN
	-- 	 V_DMS_PipelineProcessors AS VPP 
    --        ON T_Local_Processors.Processor_Name = VPP.Processor_Name
	-- WHERE Not T_Local_Processors.Processor_Name IN (SELECT Processor_Name FROM V_DMS_PipelineProcessors);

	---------------------------------------------------
	-- Exit
	---------------------------------------------------
	--
Done:
	return @myError


GO
GRANT VIEW DEFINITION ON [dbo].[ImportProcessors] TO [DDL_Viewer] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[ImportProcessors] TO [Limited_Table_Write] AS [dbo]
GO
