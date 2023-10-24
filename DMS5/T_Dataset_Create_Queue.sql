/****** Object:  Table [dbo].[T_Dataset_Create_Queue] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Dataset_Create_Queue](
	[Entry_ID] [int] IDENTITY(1,1) NOT NULL,
	[State_ID] [int] NOT NULL,
	[Dataset] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Experiment] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Instrument] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Separation_Type] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[LC_Cart] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[LC_Cart_Config] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[LC_Column] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Wellplate] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Well] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Dataset_Type] [varchar](20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Operator_Username] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[DS_Creator_Username] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Comment] [varchar](512) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Interest_Rating] [varchar](32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Request] [int] NULL,
	[Work_Package] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[EUS_Usage_Type] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[EUS_Proposal_ID] [varchar](10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[EUS_Users] [varchar](1024) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Capture_Share_Name] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Capture_Subdirectory] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Command] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Processor] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Created] [datetime] NULL,
	[Start] [datetime] NULL,
	[Finish] [datetime] NULL,
	[Completion_Code] [int] NULL,
 CONSTRAINT [PK_Dataset_Create_Queue] PRIMARY KEY CLUSTERED 
(
	[Entry_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_Dataset_Create_Queue] TO [DDL_Viewer] AS [dbo]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_Dataset_Create_Queue_Dataset] ******/
CREATE NONCLUSTERED INDEX [IX_T_Dataset_Create_Queue_Dataset] ON [dbo].[T_Dataset_Create_Queue]
(
	[Dataset] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_Dataset_Create_Queue_Instrument] ******/
CREATE NONCLUSTERED INDEX [IX_T_Dataset_Create_Queue_Instrument] ON [dbo].[T_Dataset_Create_Queue]
(
	[Instrument] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_Dataset_Create_Queue] ADD  CONSTRAINT [DF_T_Dataset_Create_Queue_State_ID]  DEFAULT ((1)) FOR [State_ID]
GO
ALTER TABLE [dbo].[T_Dataset_Create_Queue] ADD  DEFAULT ('') FOR [Work_Package]
GO
ALTER TABLE [dbo].[T_Dataset_Create_Queue] ADD  DEFAULT ('') FOR [EUS_Usage_Type]
GO
ALTER TABLE [dbo].[T_Dataset_Create_Queue] ADD  DEFAULT ('') FOR [EUS_Proposal_ID]
GO
ALTER TABLE [dbo].[T_Dataset_Create_Queue] ADD  DEFAULT ('') FOR [EUS_Users]
GO
ALTER TABLE [dbo].[T_Dataset_Create_Queue] ADD  CONSTRAINT [DF_Data_Folder_Create_Queue_Command]  DEFAULT ('add') FOR [Command]
GO
ALTER TABLE [dbo].[T_Dataset_Create_Queue] ADD  CONSTRAINT [DF_T_Dataset_Create_Queue_Created]  DEFAULT (getdate()) FOR [Created]
GO
ALTER TABLE [dbo].[T_Dataset_Create_Queue]  WITH CHECK ADD  CONSTRAINT [FK_T_Dataset_Create_Queue_T_Dataset_Create_Queue_State] FOREIGN KEY([State_ID])
REFERENCES [dbo].[T_Dataset_Create_Queue_State] ([Queue_State_ID])
GO
ALTER TABLE [dbo].[T_Dataset_Create_Queue] CHECK CONSTRAINT [FK_T_Dataset_Create_Queue_T_Dataset_Create_Queue_State]
GO
