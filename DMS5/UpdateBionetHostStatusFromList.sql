/****** Object:  StoredProcedure [dbo].[UpdateBionetHostStatusFromList] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Procedure dbo.UpdateBionetHostStatusFromList
/****************************************************
**
**	Desc: 
**		Updates the Last_Online column in T_Bionet_Hosts
**		for the computers in @hostNames
**
**	Auth:	mem
**	Date:	12/03/2015 mem - Initial version
**			12/04/2015 mem - Now auto-removing ".bionet"
**						   - Add support for including IP addresses, for example ltq_orb_3@192.168.30.78
**    
*****************************************************/
(
	@hostNames varchar(8000),	-- Comma separated list of computer names.  Optionally include IP address with each host name using the format host@IP
	@addMissingHosts tinyint = 0,
	@infoOnly tinyint = 0
)
AS
	Set NoCount On

	Declare @myRowCount int	
	Declare @myError int
	Set @myRowCount = 0
	Set @myError = 0
	
	-----------------------------------------
	-- Validate the input parameters
	-----------------------------------------
	
	Set @hostNames = IsNull(@hostNames, '')
	Set @addMissingHosts = IsNull(@addMissingHosts, 0)
	Set @infoOnly = IsNull(@infoOnly, 0)
	
	-----------------------------------------
	-- Create a temporary table
	-----------------------------------------
	
	CREATE TABLE #Tmp_Hosts (
		Host varchar(80) not null,		-- Could have Host and IP, encoded as Host@IP
		IP varchar(15) null
	)
	
	CREATE CLUSTERED INDEX #IX_Tmp_Hosts ON #Tmp_Hosts (Host)
	
	-----------------------------------------
	-- Parse the list of host names (or Host and IP combos)
	-----------------------------------------

	Declare @HostCount int = 0
	
	INSERT INTO #Tmp_Hosts (Host)
	SELECT DISTINCT Value
	FROM dbo.udfParseDelimitedList(@hostNames, ',')
	--
	SELECT @myRowCount = @@rowcount, @myError = @@error
	
	Set @HostCount = @myRowCount
	
	
	-- Split out IP address
	--
	UPDATE #Tmp_Hosts
	SET Host = SubString(FilterQ.HostAndIP, 1, AtSignLoc - 1),
	    IP = SubString(FilterQ.HostAndIP, AtSignLoc + 1, 16)
	FROM ( SELECT Host AS HostAndIP,
	              CharIndex('@', Host) AS AtSignLoc
	       FROM #Tmp_Hosts
	       WHERE Host LIKE '%@[0-9]%' ) FilterQ
	     INNER JOIN #Tmp_Hosts
	       ON FilterQ.HostAndIP = #Tmp_Hosts.Host
	--
	SELECT @myRowCount = @@rowcount, @myError = @@error


	-- Remove suffix .bionet if present
	--
	UPDATE #Tmp_Hosts
	SET Host = Replace(Host, '.bionet', '')
	WHERE Host LIKE '%.bionet'
	--
	SELECT @myRowCount = @@rowcount, @myError = @@error
		
		
	If @infoOnly <> 0
	Begin
		-----------------------------------------
		-- Preview the new info
		-----------------------------------------
		
		SELECT Src.Host,
		       Src.IP,
		       CASE
		           WHEN Target.Host IS NULL AND
		                @addMissingHosts = 0 THEN 'Host not found; will be skipped'
		           WHEN Target.Host IS NULL AND
		                @addMissingHosts <> 0 THEN 'Host not found; will be added'
		           ELSE ''
		       END AS Warning,
		       Target.Last_Online,
		       CASE
		           WHEN Target.Host IS NULL AND
		                @addMissingHosts = 0 THEN NULL
		           ELSE GetDate()
		       END AS New_Last_Online,
		       Target.IP AS Last_IP
		FROM #Tmp_Hosts Src
		     LEFT OUTER JOIN T_Bionet_Hosts Target
		       ON Target.Host = Src.Host
		ORDER BY Src.Host
		--
		SELECT @myRowCount = @@rowcount, @myError = @@error
		
	End
	Else
	Begin
		-----------------------------------------
		-- Update Last_Online for existing hosts
		-----------------------------------------
		
		UPDATE T_Bionet_Hosts
		SET Last_Online = GetDate(),
		    IP = Coalesce(Src.IP, Target.IP)
		FROM #Tmp_Hosts Src
		     INNER JOIN T_Bionet_Hosts Target
		       ON Target.Host = Src.Host
		--
		SELECT @myRowCount = @@rowcount, @myError = @@error
		
		If @myRowCount < @HostCount And @addMissingHosts <> 0
		Begin
			-- Add missing hosts
			
			INSERT INTO T_Bionet_Hosts( Host,
			                            IP,
			                            Entered,
			                            Last_Online )
			SELECT Src.Host,
			       Src.IP,
			       GetDate(),
			       GetDate()
			FROM #Tmp_Hosts Src
			     LEFT OUTER JOIN T_Bionet_Hosts Target
			       ON Target.Host = Src.Host
			WHERE Target.Host IS NULL
		    --
			SELECT @myRowCount = @@rowcount, @myError = @@error
		
		End
		
	End

	
Done:

	Return @myError


GO
GRANT EXECUTE ON [dbo].[UpdateBionetHostStatusFromList] TO [svc-dms] AS [dbo]
GO
