/****** Object:  StoredProcedure [dbo].[UpdateCPULoading] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE dbo.UpdateCPULoading
/****************************************************
**
**	Desc:
**		Update local processor list with count of CPUs
**		that are available for new tasks, given current
**		task assignments
**
**		Also updates memory usage
**	
**	Return values: 0: success, otherwise, error code
**
**
**	Auth:	grk
**			06/03/2008 grk - Initial release (http://prismtrac.pnl.gov/trac/ticket/666)
**			09/10/2010 mem - Now using READUNCOMMITTED when querying T_Job_Steps
**			10/17/2011 mem - Now populating Memory_Available
**    
*****************************************************/
(
	@message varchar(512) output
)
As
	set nocount on
	
	declare @myError int
	set @myError = 0

	declare @myRowCount int
	set @myRowCount = 0
	
	set @message = ''

	---------------------------------------------------
	-- Find job steps that are currently busy 
	-- and sum up cpu counts and memory uage for tools by machine
	-- Update T_Machines
	---------------------------------------------------
	--	
	UPDATE T_Machines
	SET    CPUs_Available = T_Machines.Total_CPUs - TX.CPUs_used,
	       Memory_Available = T_Machines.Total_Memory_MB - TX.Memory_Used
	FROM   T_Machines
	INNER JOIN 
	(
		SELECT
			M.Machine, 
			SUM(CASE WHEN JS.State = 4 THEN JS.CPU_Load ELSE 0 END) AS CPUs_used,
			SUM(CASE WHEN JS.State = 4 THEN JS.Memory_Usage_MB ELSE 0 END) AS Memory_Used
		FROM T_Job_Steps JS WITH (READUNCOMMITTED) RIGHT OUTER JOIN
             T_Machines M ON JS.Machine = M.Machine   
		GROUP BY M.Machine	
	) AS TX
	ON TX.Machine = T_Machines.Machine
	--
	SELECT @myError = @@error, @myRowCount = @@rowcount
     --
	if @myError <> 0
	begin
		set @message = 'Error updating machine CPU loading'
		goto Done
	end

	---------------------------------------------------
	-- Exit
	---------------------------------------------------
	--
Done:
	return @myError

 

GO
GRANT VIEW DEFINITION ON [dbo].[UpdateCPULoading] TO [Limited_Table_Write] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateCPULoading] TO [PNL\D3M578] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[UpdateCPULoading] TO [PNL\D3M580] AS [dbo]
GO
