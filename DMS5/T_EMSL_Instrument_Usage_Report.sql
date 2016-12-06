/****** Object:  Table [dbo].[T_EMSL_Instrument_Usage_Report] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_EMSL_Instrument_Usage_Report](
	[EMSL_Inst_ID] [int] NULL,
	[Instrument] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Type] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Start] [datetime] NULL,
	[Minutes] [int] NULL,
	[Proposal] [varchar](32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Usage] [varchar](32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Users] [varchar](1024) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Operator] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Comment] [varchar](4096) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Year] [int] NULL,
	[Month] [int] NULL,
	[ID] [int] NULL,
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
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_T_EMSL_Instrument_Usage_Report] ******/
CREATE CLUSTERED INDEX [IX_T_EMSL_Instrument_Usage_Report] ON [dbo].[T_EMSL_Instrument_Usage_Report]
(
	[Instrument] ASC,
	[Year] ASC,
	[Month] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
ALTER TABLE [dbo].[T_EMSL_Instrument_Usage_Report] ADD  CONSTRAINT [DF_T_EMSL_Instrument_Usage_Report_Updated]  DEFAULT (getdate()) FOR [Updated]
GO
