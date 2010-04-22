/****** Object:  Table [dbo].[T_Prep_LC_Run] ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Prep_LC_Run](
	[ID] [int] IDENTITY(1000,1) NOT NULL,
	[Tab] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Instrument] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Type] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[LC_Column] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Comment] [varchar](1024) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Guard_Column] [varchar](12) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	[Created] [datetime] NOT NULL,
	[OperatorPRN] [varchar](50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Digestion_Method] [varchar](128) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Sample_Type] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Project] [varchar](64) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	[Number_Of_Runs] [int] NULL,
	[Instrument_Pressure] [varchar](32) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
 CONSTRAINT [PK_T_Prep_LC_Run] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 10) ON [PRIMARY]
) ON [PRIMARY]

GO
ALTER TABLE [dbo].[T_Prep_LC_Run]  WITH CHECK ADD  CONSTRAINT [FK_T_Prep_LC_Run_T_Prep_Instruments] FOREIGN KEY([Instrument])
REFERENCES [T_Prep_Instruments] ([Name])
GO
ALTER TABLE [dbo].[T_Prep_LC_Run] CHECK CONSTRAINT [FK_T_Prep_LC_Run_T_Prep_Instruments]
GO
ALTER TABLE [dbo].[T_Prep_LC_Run]  WITH CHECK ADD  CONSTRAINT [FK_T_Prep_LC_Run_T_Prep_LC_Column] FOREIGN KEY([LC_Column])
REFERENCES [T_Prep_LC_Column] ([Column_Name])
GO
ALTER TABLE [dbo].[T_Prep_LC_Run] CHECK CONSTRAINT [FK_T_Prep_LC_Run_T_Prep_LC_Column]
GO
ALTER TABLE [dbo].[T_Prep_LC_Run] ADD  CONSTRAINT [DF_T_Prep_LC_Run_Guard_Column]  DEFAULT ('No') FOR [Guard_Column]
GO
ALTER TABLE [dbo].[T_Prep_LC_Run] ADD  CONSTRAINT [DF_T_Prep_LC_Run_Created]  DEFAULT (getdate()) FOR [Created]
GO
