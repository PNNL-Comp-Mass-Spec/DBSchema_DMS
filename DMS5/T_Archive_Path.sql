/****** Object:  Table [dbo].[T_Archive_Path] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Archive_Path](
	[AP_instrument_name_ID] [int] NOT NULL,
	[AP_archive_path] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[AP_path_ID] [int] IDENTITY(110,1) NOT NULL,
	[Note] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[AP_Function] [varchar](24) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[AP_Server_Name] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[AP_network_share_path] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[AP_archive_URL] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[AP_created] [datetime] NULL,
 CONSTRAINT [PK_T_Archive_Path] PRIMARY KEY CLUSTERED 
(
	[AP_path_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT ALTER ON [dbo].[T_Archive_Path] TO [D3L243] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[T_Archive_Path] TO [DDL_Viewer] AS [dbo]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_Archive_Path_AP_Function] ******/
CREATE NONCLUSTERED INDEX [IX_T_Archive_Path_AP_Function] ON [dbo].[T_Archive_Path]
(
	[AP_Function] ASC
)
INCLUDE ( 	[AP_instrument_name_ID],
	[AP_archive_path],
	[AP_network_share_path]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_Archive_Path] ADD  CONSTRAINT [DF_T_Archive_Path_AP_created]  DEFAULT (getdate()) FOR [AP_created]
GO
ALTER TABLE [dbo].[T_Archive_Path]  WITH CHECK ADD  CONSTRAINT [FK_T_Archive_Path_T_Archive_Path_Function] FOREIGN KEY([AP_Function])
REFERENCES [dbo].[T_Archive_Path_Function] ([APF_Function])
GO
ALTER TABLE [dbo].[T_Archive_Path] CHECK CONSTRAINT [FK_T_Archive_Path_T_Archive_Path_Function]
GO
/****** Object:  Trigger [dbo].[trig_iu_Archive_Path] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Trigger [dbo].[trig_iu_Archive_Path] on [dbo].[T_Archive_Path]
After Insert, Update
/****************************************************
**
**	Desc: 
**		Updates column AP_archive_URL for new or updated archive path entries
**
**	Auth:	mem
**	Date:	08/19/2010
**    
*****************************************************/
AS
	If @@RowCount = 0
		Return

	Set NoCount On

	If Update(ap_archive_path) OR
	   Update(AP_archive_URL)
	Begin
		UPDATE T_Archive_Path
		SET AP_archive_URL = CASE
		                         WHEN AP.ap_archive_path LIKE '/archive/dmsarch/%' THEN 
		                           'http://dms2.pnl.gov/dmsarch/' + substring(AP.ap_archive_path, 18, 256) + '/'
		                         ELSE NULL
		                     END
		FROM T_Archive_Path AP
		     INNER JOIN inserted
		       ON AP.AP_path_ID = inserted.AP_path_ID

	End

GO
ALTER TABLE [dbo].[T_Archive_Path] ENABLE TRIGGER [trig_iu_Archive_Path]
GO
