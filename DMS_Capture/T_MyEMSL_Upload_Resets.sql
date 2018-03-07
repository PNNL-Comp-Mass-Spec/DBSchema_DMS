/****** Object:  Table [dbo].[T_MyEMSL_Upload_Resets] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_MyEMSL_Upload_Resets](
	[Entry_ID] [int] IDENTITY(1,1) NOT NULL,
	[Job] [int] NOT NULL,
	[Dataset_ID] [int] NOT NULL,
	[Subfolder] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Error_Message] [varchar](256) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Entered] [datetime] NOT NULL,
 CONSTRAINT [PK_T_MyEMSL_Upload_Resets] PRIMARY KEY CLUSTERED 
(
	[Entry_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_MyEMSL_Upload_Resets] TO [DDL_Viewer] AS [dbo]
GO
/****** Object:  Index [IX_T_MyEMSL_Upload_Resets_Dataset_ID] ******/
CREATE NONCLUSTERED INDEX [IX_T_MyEMSL_Upload_Resets_Dataset_ID] ON [dbo].[T_MyEMSL_Upload_Resets]
(
	[Job] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
/****** Object:  Index [IX_T_MyEMSL_Upload_Resets_Entered] ******/
CREATE NONCLUSTERED INDEX [IX_T_MyEMSL_Upload_Resets_Entered] ON [dbo].[T_MyEMSL_Upload_Resets]
(
	[Entered] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
/****** Object:  Index [IX_T_MyEMSL_Upload_Resets_Job] ******/
CREATE NONCLUSTERED INDEX [IX_T_MyEMSL_Upload_Resets_Job] ON [dbo].[T_MyEMSL_Upload_Resets]
(
	[Job] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_MyEMSL_Upload_Resets] ADD  CONSTRAINT [DF_T_MyEMSL_Upload_Resets_Entered]  DEFAULT (getdate()) FOR [Entered]
GO
