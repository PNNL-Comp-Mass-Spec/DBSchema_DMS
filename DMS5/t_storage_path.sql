/****** Object:  Table [dbo].[T_Storage_Path] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Storage_Path](
	[SP_path_ID] [int] IDENTITY(10,1) NOT NULL,
	[SP_path] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[SP_machine_name] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[SP_vol_name_client] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[SP_vol_name_server] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[SP_function] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[SP_instrument_name] [varchar](24) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[SP_code] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[SP_description] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[SP_URL]  AS (case when [sp_function]='inbox' then NULL else (('http://'+[SP_machine_name])+'/')+replace([SP_path],'\','/') end) PERSISTED,
	[SP_created] [datetime] NULL,
	[SPath_RowVersion] [timestamp] NOT NULL,
 CONSTRAINT [PK_t_storage_path] PRIMARY KEY CLUSTERED 
(
	[SP_path_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_Storage_Path] TO [DDL_Viewer] AS [dbo]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_t_storage_path_Machine_Name_Path_ID] ******/
CREATE NONCLUSTERED INDEX [IX_t_storage_path_Machine_Name_Path_ID] ON [dbo].[T_Storage_Path]
(
	[SP_machine_name] ASC,
	[SP_path_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_Storage_Path] ADD  CONSTRAINT [DF_T_Storage_Path_SP_created]  DEFAULT (getdate()) FOR [SP_created]
GO
ALTER TABLE [dbo].[T_Storage_Path]  WITH CHECK ADD  CONSTRAINT [FK_t_storage_path_T_Instrument_Name] FOREIGN KEY([SP_instrument_name])
REFERENCES [dbo].[T_Instrument_Name] ([IN_name])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[T_Storage_Path] CHECK CONSTRAINT [FK_t_storage_path_T_Instrument_Name]
GO
/****** Object:  Trigger [dbo].[trig_u_Storage_Path] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Trigger [dbo].[trig_u_Storage_Path] on [dbo].[T_Storage_Path]
After Update
/****************************************************
**
**	Desc: 
**		Updates T_Cached_Dataset_Folder_Paths for existing datasets
**
**	Auth:	mem
**	Date:	01/22/2015 mem
**    
*****************************************************/
AS
	If @@RowCount = 0
		Return

	Set NoCount On

	If Update(SP_path) OR 
	   Update(SP_machine_name) OR 
	   Update (SP_vol_name_client)
	Begin
		UPDATE T_Cached_Dataset_Folder_Paths
		SET UpdateRequired = 1
		FROM T_Cached_Dataset_Folder_Paths DFP
		     INNER JOIN T_Dataset DS
		       ON DFP.Dataset_ID = DS.Dataset_ID
		     INNER JOIN inserted
		       ON DS.DS_storage_path_ID = inserted.SP_path_ID

	End

GO
