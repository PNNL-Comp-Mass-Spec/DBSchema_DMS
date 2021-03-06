/****** Object:  Table [dbo].[T_DatasetTypeName] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_DatasetTypeName](
	[DST_Type_ID] [int] NOT NULL,
	[DST_name] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[DST_Description] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[DST_Active] [tinyint] NOT NULL,
 CONSTRAINT [PK_T_DatasetTypeName] PRIMARY KEY NONCLUSTERED 
(
	[DST_Type_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_DatasetTypeName] TO [DDL_Viewer] AS [dbo]
GO
GRANT SELECT ON [dbo].[T_DatasetTypeName] TO [DMS_LCMSNet_User] AS [dbo]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_DatasetTypeName_Name] ******/
CREATE UNIQUE CLUSTERED INDEX [IX_T_DatasetTypeName_Name] ON [dbo].[T_DatasetTypeName]
(
	[DST_name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_DatasetTypeName] ADD  CONSTRAINT [DF_T_DatasetTypeName_DST_Active]  DEFAULT (1) FOR [DST_Active]
GO
ALTER TABLE [dbo].[T_DatasetTypeName]  WITH CHECK ADD  CONSTRAINT [FK_T_DatasetTypeName_T_YesNo] FOREIGN KEY([DST_Active])
REFERENCES [dbo].[T_YesNo] ([Flag])
GO
ALTER TABLE [dbo].[T_DatasetTypeName] CHECK CONSTRAINT [FK_T_DatasetTypeName_T_YesNo]
GO
