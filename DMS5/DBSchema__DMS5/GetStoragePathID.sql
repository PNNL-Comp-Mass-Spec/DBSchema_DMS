/****** Object:  StoredProcedure [dbo].[GetStoragePathID] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO








CREATE Procedure GetStoragePathID
/****************************************************
**
**	Desc: Gets storagePathID for given instrument name
**        that is currently assigned
**        to recieve new datasets.  
**
**	Return values: 0: failure, otherwise, storagePathID
**
**	Parameters: 
**
**		Auth: grk
**		Date: 1/26/2001
**    
*****************************************************/
	(
		@instrumentName varchar(80) = " "
	)
As
	declare @storagePathID int
	set @storagePathID = 0
	-- SELECT @storagePathID = Dataset_ID FROM T_Dataset WHERE (Dataset_Num = @datasetNum)
	SELECT @storagePathID = SP_path_ID FROM t_storage_path WHERE (SP_function = N'raw-storage') AND (SP_instrument_name = @instrumentName)
	return(@storagePathID)
GO
GRANT EXECUTE ON [dbo].[GetStoragePathID] TO [DMS_SP_User]
GO
