/****** Object:  Table [dbo].[T_Project_Usage_Stats] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Project_Usage_Stats](
	[Entry_ID] [int] IDENTITY(1,1) NOT NULL,
	[StartDate] [smalldatetime] NOT NULL,
	[EndDate] [smalldatetime] NOT NULL,
	[TheYear] [int] NOT NULL,
	[WeekOfYear] [tinyint] NOT NULL,
	[Proposal_ID] [varchar](10) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[RDS_WorkPackage] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Proposal_Active] [int] NOT NULL,
	[Project_Type_ID] [tinyint] NOT NULL,
	[Datasets] [int] NULL,
	[Jobs] [int] NULL,
	[EUS_UsageType] [smallint] NOT NULL,
	[Proposal_Type] [varchar](100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Proposal_User] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Instrument_First] [varchar](32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Instrument_Last] [varchar](32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[JobTool_First] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[JobTool_Last] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[SortKey]  AS (CONVERT([float],[TheYear]*(10000)+[WeekOfYear],(0))+([Datasets]+[Jobs])/(1000000.0)) PERSISTED,
 CONSTRAINT [PK_T_Project_Usage_Stats] PRIMARY KEY CLUSTERED 
(
	[Entry_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Index [IX_T_Project_Usage_Stats_YearAndWeek] ******/
CREATE NONCLUSTERED INDEX [IX_T_Project_Usage_Stats_YearAndWeek] ON [dbo].[T_Project_Usage_Stats]
(
	[TheYear] ASC,
	[WeekOfYear] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_Project_Usage_Stats]  WITH CHECK ADD  CONSTRAINT [FK_T_Project_Usage_Stats_T_EUS_Proposals] FOREIGN KEY([Proposal_ID])
REFERENCES [dbo].[T_EUS_Proposals] ([Proposal_ID])
GO
ALTER TABLE [dbo].[T_Project_Usage_Stats] CHECK CONSTRAINT [FK_T_Project_Usage_Stats_T_EUS_Proposals]
GO
ALTER TABLE [dbo].[T_Project_Usage_Stats]  WITH CHECK ADD  CONSTRAINT [FK_T_Project_Usage_Stats_T_EUS_UsageType] FOREIGN KEY([EUS_UsageType])
REFERENCES [dbo].[T_EUS_UsageType] ([ID])
GO
ALTER TABLE [dbo].[T_Project_Usage_Stats] CHECK CONSTRAINT [FK_T_Project_Usage_Stats_T_EUS_UsageType]
GO
ALTER TABLE [dbo].[T_Project_Usage_Stats]  WITH CHECK ADD  CONSTRAINT [FK_T_Project_Usage_Stats_T_Project_Usage_Stats] FOREIGN KEY([Project_Type_ID])
REFERENCES [dbo].[T_Project_Usage_Types] ([Project_Type_ID])
GO
ALTER TABLE [dbo].[T_Project_Usage_Stats] CHECK CONSTRAINT [FK_T_Project_Usage_Stats_T_Project_Usage_Stats]
GO
