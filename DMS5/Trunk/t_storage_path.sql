/****** Object:  Table [dbo].[t_storage_path] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[t_storage_path](
	[SP_path_ID] [int] IDENTITY(10,1) NOT NULL,
	[SP_path] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[SP_machine_name] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[SP_vol_name_client] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[SP_vol_name_server] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[SP_function] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[SP_instrument_name] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[SP_code] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[SP_description] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[SP_URL] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_t_storage_path] PRIMARY KEY NONCLUSTERED 
(
	[SP_path_ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 10) ON [PRIMARY]
) ON [PRIMARY]

GO

/****** Object:  Index [IX_t_storage_path_Machine_Name_Path_ID] ******/
CREATE NONCLUSTERED INDEX [IX_t_storage_path_Machine_Name_Path_ID] ON [dbo].[t_storage_path] 
(
	[SP_machine_name] ASC,
	[SP_path_ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 10) ON [PRIMARY]
GO

/****** Object:  Trigger [dbo].[trig_iu_Storage_Path] ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE Trigger [dbo].[trig_iu_Storage_Path] on [dbo].[t_storage_path]
After Insert, Update
/****************************************************
**
**	Desc: 
**		Updates column SP_URL for new or updated storage path entries
**
**	Auth:	mem
**	Date:	08/19/2010
**    
*****************************************************/
AS
	If @@RowCount = 0
		Return

	Set NoCount On

	If Update(sp_function) OR
	   Update(SP_machine_name) OR
	   Update(SP_path) OR
	   Update(SP_URL)
	Begin
		UPDATE T_Storage_Path
		SET SP_URL = CASE
		                 WHEN SP.sp_function = 'inbox' THEN NULL
		                 ELSE (('http://' + SP.SP_machine_name) + '/') + replace(SP.SP_path, '\', '/')
		             END
		FROM T_Storage_Path SP
		     INNER JOIN inserted
		       ON SP.SP_path_ID = inserted.SP_path_ID

	End


GO
