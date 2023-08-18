/****** Object:  Table [dbo].[T_Data_Package] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Data_Package](
	[Data_Pkg_ID] [int] IDENTITY(100,1) NOT NULL,
	[Name] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Package_Type] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Description] [varchar](2048) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Comment] [varchar](1024) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Owner] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Requester] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Created] [datetime] NOT NULL,
	[Last_Modified] [datetime] NULL,
	[State] [varchar](32) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Package_File_Folder] [varchar](256) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Path_Root] [int] NULL,
	[Path_Year] [varchar](6) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Path_Team] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Biomaterial_Item_Count] [int] NOT NULL,
	[Experiment_Item_Count] [int] NOT NULL,
	[EUS_Proposal_Item_Count] [int] NOT NULL,
	[Dataset_Item_Count] [int] NOT NULL,
	[Analysis_Job_Item_Count] [int] NOT NULL,
	[Total_Item_Count] [int] NOT NULL,
	[Mass_Tag_Database] [varchar](1024) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Wiki_Page_Link] [varchar](1024) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Instrument] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[EUS_Person_ID] [int] NULL,
	[EUS_Proposal_ID] [varchar](10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[EUS_Instrument_ID] [int] NULL,
	[Data_DOI] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Manuscript_DOI] [varchar](255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[ID]  AS ([Data_Pkg_ID]) PERSISTED NOT NULL,
 CONSTRAINT [PK_T_Data_Package] PRIMARY KEY CLUSTERED 
(
	[Data_Pkg_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_Data_Package] TO [DDL_Viewer] AS [dbo]
GO
GRANT SELECT ON [dbo].[T_Data_Package] TO [DMS_SP_User] AS [dbo]
GO
GRANT UPDATE ON [dbo].[T_Data_Package] TO [DMS_SP_User] AS [dbo]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_Data_Package_Name] ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_T_Data_Package_Name] ON [dbo].[T_Data_Package]
(
	[Name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_Data_Package_Package_File_Folder] ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_T_Data_Package_Package_File_Folder] ON [dbo].[T_Data_Package]
(
	[Package_File_Folder] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_Data_Package_State_include_ID] ******/
CREATE NONCLUSTERED INDEX [IX_T_Data_Package_State_include_ID] ON [dbo].[T_Data_Package]
(
	[State] ASC
)
INCLUDE([Data_Pkg_ID]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_Data_Package] ADD  CONSTRAINT [DF_T_Data_Package_Package_Type]  DEFAULT ('General') FOR [Package_Type]
GO
ALTER TABLE [dbo].[T_Data_Package] ADD  CONSTRAINT [DF_T_Data_Package_Description]  DEFAULT ('') FOR [Description]
GO
ALTER TABLE [dbo].[T_Data_Package] ADD  CONSTRAINT [DF_T_Data_Package_Comment]  DEFAULT ('') FOR [Comment]
GO
ALTER TABLE [dbo].[T_Data_Package] ADD  CONSTRAINT [DF_T_Data_Package_Created]  DEFAULT (getdate()) FOR [Created]
GO
ALTER TABLE [dbo].[T_Data_Package] ADD  CONSTRAINT [DF_T_Data_Package_State]  DEFAULT ('Active') FOR [State]
GO
ALTER TABLE [dbo].[T_Data_Package] ADD  CONSTRAINT [DF_T_Data_Package_Path_Year]  DEFAULT (datepart(year,getdate())) FOR [Path_Year]
GO
ALTER TABLE [dbo].[T_Data_Package] ADD  CONSTRAINT [DF_T_Data_Package_Research_Team]  DEFAULT ('General') FOR [Path_Team]
GO
ALTER TABLE [dbo].[T_Data_Package] ADD  CONSTRAINT [DF_T_Data_Package_Biomaterial_Item_Count]  DEFAULT ((0)) FOR [Biomaterial_Item_Count]
GO
ALTER TABLE [dbo].[T_Data_Package] ADD  CONSTRAINT [DF_T_Data_Package_Experiment_Item_Count]  DEFAULT ((0)) FOR [Experiment_Item_Count]
GO
ALTER TABLE [dbo].[T_Data_Package] ADD  CONSTRAINT [DF_T_Data_Package_EUS_Proposal_Item_Count]  DEFAULT ((0)) FOR [EUS_Proposal_Item_Count]
GO
ALTER TABLE [dbo].[T_Data_Package] ADD  CONSTRAINT [DF_T_Data_Package_Dataset_Item_Count]  DEFAULT ((0)) FOR [Dataset_Item_Count]
GO
ALTER TABLE [dbo].[T_Data_Package] ADD  CONSTRAINT [DF_T_Data_Package_Analysis_Job_Item_Count]  DEFAULT ((0)) FOR [Analysis_Job_Item_Count]
GO
ALTER TABLE [dbo].[T_Data_Package] ADD  CONSTRAINT [DF_T_Data_Package_Total_Item_Count]  DEFAULT ((0)) FOR [Total_Item_Count]
GO
ALTER TABLE [dbo].[T_Data_Package]  WITH CHECK ADD  CONSTRAINT [FK_T_Data_Package_T_Data_Package_State] FOREIGN KEY([State])
REFERENCES [dbo].[T_Data_Package_State] ([Name])
GO
ALTER TABLE [dbo].[T_Data_Package] CHECK CONSTRAINT [FK_T_Data_Package_T_Data_Package_State]
GO
ALTER TABLE [dbo].[T_Data_Package]  WITH CHECK ADD  CONSTRAINT [FK_T_Data_Package_T_Data_Package_Storage] FOREIGN KEY([Path_Root])
REFERENCES [dbo].[T_Data_Package_Storage] ([ID])
GO
ALTER TABLE [dbo].[T_Data_Package] CHECK CONSTRAINT [FK_T_Data_Package_T_Data_Package_Storage]
GO
ALTER TABLE [dbo].[T_Data_Package]  WITH CHECK ADD  CONSTRAINT [FK_T_Data_Package_T_Data_Package_Teams] FOREIGN KEY([Path_Team])
REFERENCES [dbo].[T_Data_Package_Teams] ([Team_Name])
GO
ALTER TABLE [dbo].[T_Data_Package] CHECK CONSTRAINT [FK_T_Data_Package_T_Data_Package_Teams]
GO
ALTER TABLE [dbo].[T_Data_Package]  WITH CHECK ADD  CONSTRAINT [FK_T_Data_Package_T_Data_Package_Type] FOREIGN KEY([Package_Type])
REFERENCES [dbo].[T_Data_Package_Type] ([Name])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[T_Data_Package] CHECK CONSTRAINT [FK_T_Data_Package_T_Data_Package_Type]
GO
