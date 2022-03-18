/****** Object:  Table [dbo].[T_EMSL_Instrument_Usage_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_EMSL_Instrument_Usage_Report](
	[EMSL_Inst_ID] [int] NULL,
	[Instrument] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[DMS_Inst_ID] [int] NOT NULL,
	[Type] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Start] [datetime] NULL,
	[Minutes] [int] NULL,
	[Proposal] [varchar](32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Usage] [varchar](32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Usage_Type] [tinyint] NULL,
	[Users] [varchar](1024) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Operator] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Comment] [varchar](4096) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Year] [int] NULL,
	[Month] [int] NULL,
	[Dataset_ID] [int] NOT NULL,
	[Dataset_ID_Acq_Overlap] [int] NULL,
	[Seq] [int] NOT NULL,
	[Updated] [datetime] NOT NULL,
	[UpdatedBy] [varchar](32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_EMSL_Instrument_Usage_Report] PRIMARY KEY NONCLUSTERED 
(
	[Seq] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
) ON [PRIMARY]

GO
GRANT VIEW DEFINITION ON [dbo].[T_EMSL_Instrument_Usage_Report] TO [DDL_Viewer] AS [dbo]
GO
/****** Object:  Index [IX_T_EMSL_Instrument_Usage_Report] ******/
CREATE CLUSTERED INDEX [IX_T_EMSL_Instrument_Usage_Report] ON [dbo].[T_EMSL_Instrument_Usage_Report]
(
	[Year] ASC,
	[Month] ASC,
	[DMS_Inst_ID] ASC,
	[Start] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
/****** Object:  Index [IX_T_EMSL_Instrument_Usage_Report_DMS_Inst_ID_Start] ******/
CREATE NONCLUSTERED INDEX [IX_T_EMSL_Instrument_Usage_Report_DMS_Inst_ID_Start] ON [dbo].[T_EMSL_Instrument_Usage_Report]
(
	[DMS_Inst_ID] ASC,
	[Start] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_EMSL_Instrument_Usage_Report_Type_DatasetID] ******/
CREATE NONCLUSTERED INDEX [IX_T_EMSL_Instrument_Usage_Report_Type_DatasetID] ON [dbo].[T_EMSL_Instrument_Usage_Report]
(
	[Type] ASC,
	[Dataset_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_EMSL_Instrument_Usage_Report] ADD  CONSTRAINT [DF_T_EMSL_Instrument_Usage_Report_DMS_Inst_ID]  DEFAULT ((1)) FOR [DMS_Inst_ID]
GO
ALTER TABLE [dbo].[T_EMSL_Instrument_Usage_Report] ADD  CONSTRAINT [DF_T_EMSL_Instrument_Usage_Report_Usage_Type]  DEFAULT ((1)) FOR [Usage_Type]
GO
ALTER TABLE [dbo].[T_EMSL_Instrument_Usage_Report] ADD  CONSTRAINT [DF_T_EMSL_Instrument_Usage_Report_Updated]  DEFAULT (getdate()) FOR [Updated]
GO
ALTER TABLE [dbo].[T_EMSL_Instrument_Usage_Report]  WITH CHECK ADD  CONSTRAINT [FK_T_EMSL_Instrument_Usage_Report_T_EMSL_Instrument_Usage_Type] FOREIGN KEY([Usage_Type])
REFERENCES [dbo].[T_EMSL_Instrument_Usage_Type] ([ID])
GO
ALTER TABLE [dbo].[T_EMSL_Instrument_Usage_Report] CHECK CONSTRAINT [FK_T_EMSL_Instrument_Usage_Report_T_EMSL_Instrument_Usage_Type]
GO
ALTER TABLE [dbo].[T_EMSL_Instrument_Usage_Report]  WITH CHECK ADD  CONSTRAINT [FK_T_EMSL_Instrument_Usage_Report_T_EMSL_Instruments] FOREIGN KEY([EMSL_Inst_ID])
REFERENCES [dbo].[T_EMSL_Instruments] ([EUS_Instrument_ID])
GO
ALTER TABLE [dbo].[T_EMSL_Instrument_Usage_Report] CHECK CONSTRAINT [FK_T_EMSL_Instrument_Usage_Report_T_EMSL_Instruments]
GO
ALTER TABLE [dbo].[T_EMSL_Instrument_Usage_Report]  WITH CHECK ADD  CONSTRAINT [FK_T_EMSL_Instrument_Usage_Report_T_Instrument_Name] FOREIGN KEY([DMS_Inst_ID])
REFERENCES [dbo].[T_Instrument_Name] ([Instrument_ID])
GO
ALTER TABLE [dbo].[T_EMSL_Instrument_Usage_Report] CHECK CONSTRAINT [FK_T_EMSL_Instrument_Usage_Report_T_Instrument_Name]
GO
