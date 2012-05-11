/****** Object:  StoredProcedure [dbo].[UpdateDMSPrepState] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE UpdateDMSPrepState
/****************************************************
**
**  Desc:
**  Update prep LC state in DMS
**
**  Return values: 0: success, otherwise, error code
**
**  Parameters:
**
**  Auth:	grk
**  Date:	05/08/2010 grk - Initial Veresion
**    
*****************************************************/
(
	@job INT,
	@Script varchar(64),
	@newJobStateInBroker int,
	@message varchar(512) output
)
As
	set nocount on

	declare @myError int
	declare @myRowCount int
	set @myError = 0
	set @myRowCount = 0

	---------------------------------------------------
	-- 
	---------------------------------------------------
	--
	IF @Script = 'HPLCSequenceCapture'
	BEGIN
		DECLARE @prepLCID INT
		--
		SELECT
			@prepLCID = CONVERT(INT, xmlNode.value('@Value', 'nvarchar(128)'))
		FROM
			T_Job_Parameters cross apply Parameters.nodes('//Param') AS R(xmlNode)
		WHERE
			T_Job_Parameters.Job = @job AND
			(xmlNode.value('@Name', 'nvarchar(128)') = 'ID') 
			
		DECLARE @storagePathID INT
		--
		SELECT
			@storagePathID = CONVERT(INT, xmlNode.value('@Value', 'nvarchar(128)'))
		FROM
			T_Job_Parameters cross apply Parameters.nodes('//Param') AS R(xmlNode)
		WHERE
			T_Job_Parameters.Job = @job AND
			(xmlNode.value('@Name', 'nvarchar(128)') = 'Storage_Path_ID') 

		IF @newJobStateInBroker = 3
		BEGIN 
			EXEC @myError = S_SetPrepLCTaskComplete @prepLCID, @storagePathID, 0, @message OUTPUT
		END

		IF @newJobStateInBroker = 5
		BEGIN 
			EXEC @myError = S_SetPrepLCTaskComplete @prepLCID, 0, 1, @message output
		END

	END

	return @myError



GO
